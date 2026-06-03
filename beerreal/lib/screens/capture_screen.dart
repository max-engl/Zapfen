import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import '../features/drinks/models/drink_model.dart';
import '../features/drinks/providers/drink_provider.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/services/post_service.dart';
import '../widgets/pint_loading.dart';
import 'drink_picker_sheet.dart';

enum _Stage { initializing, aim, review, describe, uploading }

// ── Main Screen ───────────────────────────────────────────────────────────────

class CaptureScreen extends StatefulWidget {
  final PostService postService;
  final DrinkProvider drinkProvider;
  final VoidCallback onClose;
  final ValueChanged<FeedPost> onPosted;

  const CaptureScreen({
    super.key,
    required this.postService,
    required this.drinkProvider,
    required this.onClose,
    required this.onPosted,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  _Stage _stage = _Stage.initializing;
  String? _initError;
  CameraController? _rearCtrl;
  CameraController? _frontCtrl;
  CameraDescription? _frontDesc;
  Uint8List? _imageBytes;
  Uint8List? _selfieBytes;
  bool _photosSwapped = false;
  int? _selfieCountdown;
  final _captionCtrl = TextEditingController();
  int? _rating;
  String? _uploadError;
  double? _lat;
  double? _lng;
  String _locationText = 'Ortung…';
  String _locationHint = 'Standort wird ermittelt';
  DrinkModel? _selectedDrink = const DrinkModel(
    id: '__bier',
    name: 'Bier',
    emoji: '🍺',
    isDefault: true,
    isCustom: false,
  );
  late final AnimationController _flashAnim;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _flashAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _initCameras();
    _captureLocation();
  }

  @override
  void dispose() {
    _rearCtrl?.dispose();
    _frontCtrl?.dispose();
    _captionCtrl.dispose();
    _flashAnim.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      final cameras = await availableCameras();
      final rearDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final frontDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      // Only open rear camera during aim — front camera opens after shutter.
      final rearCtrl = CameraController(
        rearDesc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await rearCtrl.initialize();
      await rearCtrl.setFlashMode(FlashMode.off);

      if (!mounted) {
        rearCtrl.dispose();
        return;
      }
      setState(() {
        _rearCtrl = rearCtrl;
        _frontDesc = frontDesc;
        _stage = _Stage.aim;
      });
    } catch (_) {
      if (mounted) setState(() => _initError = 'Kamera nicht verfügbar');
    }
  }

  Future<void> _captureLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Standort nicht verfügbar';
            _locationHint = 'Zugriff verweigert';
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationText = 'Ortung…';
        _locationHint = 'Adresse wird aufgelöst';
      });

      // Reverse geocode via Nominatim (no API key required)
      try {
        final dio = Dio();
        final resp = await dio.get<Map<String, dynamic>>(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'lat': pos.latitude,
            'lon': pos.longitude,
            'format': 'json',
          },
          options: Options(
            headers: {'User-Agent': 'Zapfen/1.0'},
            receiveTimeout: const Duration(seconds: 6),
          ),
        );
        if (!mounted) return;
        final address = (resp.data?['address'] as Map?)
            ?.cast<String, dynamic>();
        if (address != null) {
          final suburb =
              address['suburb'] as String? ??
              address['neighbourhood'] as String? ??
              address['quarter'] as String? ??
              '';
          final city =
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              '';
          final label = suburb.isNotEmpty && city.isNotEmpty
              ? '$suburb, $city'
              : city.isNotEmpty
              ? city
              : suburb.isNotEmpty
              ? suburb
              : (resp.data?['display_name'] as String? ?? '')
                    .split(',')
                    .first
                    .trim();
          setState(() {
            _locationText = label.isNotEmpty
                ? label
                : '${pos.latitude.toStringAsFixed(4)}°, ${pos.longitude.toStringAsFixed(4)}°';
            _locationHint = 'GPS · genau auf ~${pos.accuracy.round()}m';
          });
        } else {
          setState(() {
            _locationText =
                '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
            _locationHint = 'GPS-Koordinaten';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _locationText =
                '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
            _locationHint = 'GPS-Koordinaten';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Standort nicht verfügbar';
          _locationHint = 'Position konnte nicht ermittelt werden';
        });
      }
    }
  }

  Future<void> _shutter() async {
    // Guard: prevent re-entry during the entire rear→countdown→selfie sequence
    if (_imageBytes != null || _selfieCountdown != null) return;

    HapticFeedback.heavyImpact();
    _flashAnim.reverse(from: 1.0);
    final rear = _rearCtrl;
    if (rear == null || !rear.value.isInitialized) return;

    CameraController? frontCtrl;
    try {
      // 1. Take rear photo with the back camera, freeze the main view immediately
      final rearFile = await rear.takePicture();
      final imageBytes = await rearFile.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = imageBytes);

      // 2. Open the front camera now — never have both cameras open at the same time
      final frontDesc = _frontDesc;
      if (frontDesc != null) {
        final fc = CameraController(
          frontDesc,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        try {
          await fc.initialize();
          await fc.setFlashMode(FlashMode.off);
          frontCtrl = fc;
          if (mounted) setState(() => _frontCtrl = fc);
        } catch (_) {
          await fc.dispose();
        }
      }

      // 3. Countdown — selfie inset shows live front-camera preview
      for (int i = 2; i >= 1; i--) {
        if (!mounted) {
          await frontCtrl?.dispose();
          return;
        }
        setState(() => _selfieCountdown = i);
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) {
        await frontCtrl?.dispose();
        return;
      }
      setState(() => _selfieCountdown = null);

      // 4. Take selfie
      Uint8List? selfieBytes;
      if (frontCtrl != null && frontCtrl.value.isInitialized) {
        try {
          final selfieFile = await frontCtrl.takePicture();
          selfieBytes = await selfieFile.readAsBytes();
        } catch (_) {}
      }

      // 5. Clear front camera from state before disposing to avoid double-dispose in widget.dispose()
      if (!mounted) {
        await frontCtrl?.dispose();
        return;
      }
      setState(() {
        _frontCtrl = null;
        _selfieBytes = selfieBytes;
        _stage = _Stage.review;
      });
      await _disposeFrontAfterDetach(frontCtrl);
    } catch (_) {
      if (mounted) {
        setState(() {
          _selfieCountdown = null;
          _frontCtrl = null;
        });
      }
      await _disposeFrontAfterDetach(frontCtrl);
    }
  }

  Future<void> _disposeFrontAfterDetach(CameraController? ctrl) async {
    if (ctrl == null) return;
    if (mounted) {
      if (identical(_frontCtrl, ctrl)) {
        setState(() => _frontCtrl = null);
      }
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      await ctrl.dispose();
    } catch (_) {}
  }

  Future<void> _upload() async {
    if (_imageBytes == null || _selfieBytes == null) return;
    setState(() {
      _stage = _Stage.uploading;
      _uploadError = null;
    });
    try {
      // Always upload main as main and selfie as selfie regardless of display swap
      final post = await widget.postService.uploadPost(
        imageBytes: _imageBytes!,
        filename: 'photo.jpg',
        selfieBytes: _selfieBytes!,
        selfieFilename: 'selfie.jpg',
        caption: _captionCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        drinkName: _selectedDrink?.name,
        drinkEmoji: _selectedDrink?.emoji,
        rating: _rating,
      );
      if (mounted) widget.onPosted(post);
    } catch (_) {
      if (mounted) {
        setState(() {
          _stage = _Stage.describe;
          _uploadError = 'Upload fehlgeschlagen. Bitte erneut versuchen.';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final ctrl = _rearCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await ctrl.setFlashMode(next);
    if (mounted) setState(() => _flashMode = next);
  }

  void _openDrinkPicker() {
    if (widget.drinkProvider.defaults.isEmpty) {
      widget.drinkProvider.load();
    }
    DrinkPickerSheet.show(
      context,
      provider: widget.drinkProvider,
      current: _selectedDrink,
      onSelect: (drink) => setState(() => _selectedDrink = drink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Material(
      color: Colors.black,
      child: AnimatedBuilder(
        animation: _flashAnim,
        builder: (context, child) => Stack(
          children: [
            child!,
            if (_flashAnim.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _flashAnim.value,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              final slide =
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return SlideTransition(
                position: slide,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(key: ValueKey(_stage), child: _buildStage(t)),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(PintTheme t) {
    return switch (_stage) {
      _Stage.initializing => _buildInit(t),
      _Stage.aim => _buildAim(t),
      _Stage.review => _buildReview(t),
      _Stage.describe || _Stage.uploading => _buildDescribe(t),
    };
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Widget _buildInit(PintTheme t) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _CamTopBar(
          t: t,
          label: 'JETZT ZAPFEN',
          sub: 'Prompt schließt in 84 Min',
          onClose: widget.onClose,
          flashMode: _flashMode,
        ),
        Expanded(
          child: Center(
            child: _initError != null
                ? Text(
                    _initError!,
                    style: const TextStyle(
                      color: Color(0x8CFFFFFF),
                      fontSize: 14,
                    ),
                  )
                : const PintLogoLoaderInline(size: 48),
          ),
        ),
      ],
    );
  }

  // ── Aim ───────────────────────────────────────────────────────────────────

  Widget _buildAim(PintTheme t) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _CamTopBar(
          t: t,
          label: 'JETZT ZAPFEN',
          sub: 'Prompt schließt in 84 Min',
          onClose: widget.onClose,
          flashMode: _flashMode,
          onFlashToggle: _toggleFlash,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Freeze main image as soon as it's captured
                      if (_imageBytes != null)
                        Image.memory(_imageBytes!, fit: BoxFit.cover)
                      else
                        _CamFill(ctrl: _rearCtrl!),
                      const _AimGuides(),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _SelfieInset(ctrl: _frontCtrl),
                      ),
                      if (_selfieCountdown != null)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0x66000000),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_selfieCountdown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 80,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'SELFIE IN KÜRZE',
                                    style: TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // LIVE badge opposite the selfie inset
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xB2000000),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _imageBytes != null
                                    ? 'AUFGENOMMEN'
                                    : 'HINTEN · LIVE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _ModeRail(t: t),
        _CamControls(t: t, onShutter: _shutter),
      ],
    );
  }

  // ── Review ────────────────────────────────────────────────────────────────

  Widget _buildReview(PintTheme t) {
    final img = _imageBytes;
    if (img == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 8),
        _CamTopBar(
          t: t,
          label: 'AUFGENOMMEN',
          sub: '2 von 2 · hinten + vorne',
          onClose: widget.onClose,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _PhotoDualFrame(
              imageBytes: img,
              selfieBytes: _selfieBytes,
              t: t,
              ringPulse: true,
              swapped: _photosSwapped,
              onSwap: _selfieBytes != null
                  ? () => setState(() => _photosSwapped = !_photosSwapped)
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  t: t,
                  onTap: () => setState(() {
                    _stage = _Stage.aim;
                    _imageBytes = null;
                    _selfieBytes = null;
                    _photosSwapped = false;
                  }),
                  label: 'Nochmal',
                  leadIcon: Icons.refresh_rounded,
                  primary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  t: t,
                  onTap: () => setState(() => _stage = _Stage.describe),
                  label: 'Verwenden',
                  trailIcon: Icons.chevron_right_rounded,
                  primary: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Describe ──────────────────────────────────────────────────────────────

  Widget _buildDescribe(PintTheme t) {
    final img = _imageBytes;
    if (img == null) return const SizedBox.shrink();
    final uploading = _stage == _Stage.uploading;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Row(
              children: [
                _CircleBtn(
                  onTap: uploading
                      ? null
                      : () => setState(() => _stage = _Stage.review),
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 10, color: t.gold),
                    const SizedBox(width: 6),
                    Text(
                      'BESCHREIBE DEIN BIER',
                      style: TextStyle(
                        color: t.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(width: 38),
              ],
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                keyboardHeight > 0 ? keyboardHeight + 16 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoThumb(
                        imageBytes: img,
                        selfieBytes: _selfieBytes,
                        swapped: _photosSwapped,
                        onSwap: _selfieBytes != null && !uploading
                            ? () => setState(
                                () => _photosSwapped = !_photosSwapped,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BIER · GERADE EBEN',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Zeig deinen Freunden,\nwas in deinem Glas ist.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: uploading
                                    ? null
                                    : () => setState(
                                        () => _stage = _Stage.review,
                                      ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x14FFFFFF),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0x14FFFFFF),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        color: Color(0xB3FFFFFF),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Nochmal',
                                        style: TextStyle(
                                          color: Color(0xB3FFFFFF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _StarRatingRow(
                    rating: _rating,
                    enabled: !uploading,
                    onRate: (r) => setState(() => _rating = r),
                  ),
                  const SizedBox(height: 14),
                  _DrinkQuickPick(
                    t: t,
                    selected: _selectedDrink,
                    onSelect: uploading
                        ? null
                        : (d) => setState(() => _selectedDrink = d),
                    onMore: uploading ? null : _openDrinkPicker,
                  ),
                  const SizedBox(height: 14),
                  _CaptionField(t: t, ctrl: _captionCtrl, enabled: !uploading),
                  const SizedBox(height: 10),
                  _LocationMeta(
                    t: t,
                    locationText: _locationText,
                    locationHint: _locationHint,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Footer — slides up with keyboard
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              keyboardHeight > 0 ? keyboardHeight + 8 : 28,
            ),
            child: Column(
              children: [
                if (_uploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _uploadError!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: uploading ? null : _upload,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: t.gold,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: uploading
                        ? Center(
                            child: PintDots(
                              color: t.goldInk,
                              dotSize: 6,
                              spacing: 5,
                            ),
                          )
                        : Center(
                            child: Text(
                              'An deinen Kreis posten',
                              style: TextStyle(
                                color: t.goldInk,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Camera top bar ────────────────────────────────────────────────────────────

class _CamTopBar extends StatelessWidget {
  final PintTheme t;
  final String label;
  final String? sub;
  final VoidCallback onClose;
  final FlashMode flashMode;
  final VoidCallback? onFlashToggle;

  const _CamTopBar({
    required this.t,
    required this.label,
    this.sub,
    required this.onClose,
    this.flashMode = FlashMode.off,
    this.onFlashToggle,
  });

  @override
  Widget build(BuildContext context) {
    final torchOn = flashMode == FlashMode.torch;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _CircleBtn(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 10, color: t.gold),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: t.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              if (sub != null) ...[
                const SizedBox(height: 3),
                Text(
                  sub!,
                  style: const TextStyle(
                    color: Color(0x8CFFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          _CircleBtn(
            onTap: onFlashToggle,
            child: Icon(
              torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: torchOn ? const Color(0xFFFFD60A) : Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Camera preview fill ───────────────────────────────────────────────────────

class _CamFill extends StatelessWidget {
  final CameraController ctrl;
  const _CamFill({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final previewSize = ctrl.value.previewSize;
    if (!ctrl.value.isInitialized || previewSize == null) {
      return const ColoredBox(color: Colors.black);
    }
    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(ctrl),
        ),
      ),
    );
  }
}

// ── Selfie inset: live front camera preview or placeholder ────────────────────

class _SelfieInset extends StatelessWidget {
  final CameraController? ctrl;
  const _SelfieInset({this.ctrl});

  @override
  Widget build(BuildContext context) {
    final hasLive = ctrl != null && ctrl!.value.isInitialized;
    return Container(
      width: 96,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x2EFFFFFF), spreadRadius: 1, blurRadius: 0),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (hasLive)
              _CamFill(ctrl: ctrl!)
            else
              const Center(
                child: Icon(
                  Icons.face_retouching_natural,
                  color: Color(0x4DFFFFFF),
                  size: 36,
                ),
              ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xB2000000),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasLive ? 'VORNE · LIVE' : 'VORNE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aiming guides overlay (dashed rect + corner marks + crosshair) ────────────

class _AimGuides extends StatelessWidget {
  const _AimGuides();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AimPainter(),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xD9FFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 28.0;
    const radius = 22.0;
    const corner = 22.0;

    // Dashed rounded rect
    final dashPaint = Paint()
      ..color = const Color(0x59FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
    _drawDashed(canvas, path, dashPaint, 6, 5);

    // Corner marks
    final cp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final corners = [
      // tl
      [
        Offset(inset, inset + corner),
        Offset(inset, inset),
        Offset(inset + corner, inset),
      ],
      // tr
      [
        Offset(w - inset - corner, inset),
        Offset(w - inset, inset),
        Offset(w - inset, inset + corner),
      ],
      // bl
      [
        Offset(inset, h - inset - corner),
        Offset(inset, h - inset),
        Offset(inset + corner, h - inset),
      ],
      // br
      [
        Offset(w - inset - corner, h - inset),
        Offset(w - inset, h - inset),
        Offset(w - inset, h - inset - corner),
      ],
    ];
    for (final pts in corners) {
      final p = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(p, cp);
    }
  }

  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint,
    double on,
    double off,
  ) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final len = draw ? on : off;
        if (draw) canvas.drawPath(m.extractPath(d, d + len), paint);
        d += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Mode rail ─────────────────────────────────────────────────────────────────

class _ModeRail extends StatelessWidget {
  final PintTheme t;
  const _ModeRail({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x0FFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.gold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'DOPPELAUFNAHME · HINTEN + VORNE',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Camera controls (gallery / shutter / flip) ────────────────────────────────

class _CamControls extends StatelessWidget {
  final PintTheme t;
  final VoidCallback onShutter;
  const _CamControls({required this.t, required this.onShutter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 30),
      child: Center(
        child: GestureDetector(
          onTap: onShutter,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: t.gold),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: t.goldInk.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Captured dual frame (review stage) ───────────────────────────────────────

class _PhotoDualFrame extends StatelessWidget {
  final Uint8List imageBytes;
  final Uint8List? selfieBytes;
  final PintTheme t;
  final bool ringPulse;
  final bool swapped;
  final VoidCallback? onSwap;

  const _PhotoDualFrame({
    required this.imageBytes,
    this.selfieBytes,
    required this.t,
    this.ringPulse = false,
    this.swapped = false,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelfie = selfieBytes != null;
    final bigBytes = (swapped && hasSelfie) ? selfieBytes! : imageBytes;
    final smallBytes = hasSelfie ? (swapped ? imageBytes : selfieBytes!) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bigBytes, fit: BoxFit.cover),

            if (smallBytes != null)
              Positioned(
                top: 14,
                left: 14,
                child: GestureDetector(
                  onTap: onSwap,
                  child: Container(
                    width: 96,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: ringPulse
                          ? [
                              BoxShadow(
                                color: t.gold.withValues(alpha: 0.55),
                                spreadRadius: 3,
                                blurRadius: 0,
                              ),
                            ]
                          : [
                              const BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(smallBytes, fit: BoxFit.cover),
                          // Swap hint icon
                          if (onSwap != null)
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xB2000000),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // CAPTURED badge
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: t.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 11, color: t.goldInk),
                    const SizedBox(width: 4),
                    Text(
                      'AUFGENOMMEN',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small photo thumbnail (describe header) ───────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  final Uint8List imageBytes;
  final Uint8List? selfieBytes;
  final bool swapped;
  final VoidCallback? onSwap;

  const _PhotoThumb({
    required this.imageBytes,
    this.selfieBytes,
    this.swapped = false,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelfie = selfieBytes != null;
    final bigBytes = (swapped && hasSelfie) ? selfieBytes! : imageBytes;
    final smallBytes = hasSelfie ? (swapped ? imageBytes : selfieBytes!) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 84,
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bigBytes, fit: BoxFit.cover),
            if (smallBytes != null)
              Positioned(
                top: 5,
                left: 5,
                child: GestureDetector(
                  onTap: onSwap,
                  child: Container(
                    width: 28,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2EFFFFFF),
                          spreadRadius: 1,
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.5),
                      child: Image.memory(smallBytes, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Action button (Retake / Use these) ───────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final PintTheme t;
  final VoidCallback onTap;
  final String label;
  final IconData? leadIcon;
  final IconData? trailIcon;
  final bool primary;

  const _ActionBtn({
    required this.t,
    required this.onTap,
    required this.label,
    this.leadIcon,
    this.trailIcon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: primary ? t.gold : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadIcon != null) ...[
              Icon(
                leadIcon,
                color: primary ? t.goldInk : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: primary ? t.goldInk : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (trailIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                trailIcon,
                color: primary ? t.goldInk : Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Caption field ─────────────────────────────────────────────────────────────

class _CaptionField extends StatelessWidget {
  final PintTheme t;
  final TextEditingController ctrl;
  final bool enabled;
  static const _max = 140;

  const _CaptionField({
    required this.t,
    required this.ctrl,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          TextField(
            controller: ctrl,
            readOnly: !enabled,
            maxLines: null,
            minLines: 3,
            maxLength: _max,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.2,
            ),
            decoration: const InputDecoration(
              hintText: 'Sag etwas dazu…',
              hintStyle: TextStyle(color: Color(0x66FFFFFF)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '@erwähnen',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#tag',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (_, val, __) {
                  final len = val.text.length;
                  return Text(
                    '$len/$_max',
                    style: TextStyle(
                      color: len > _max - 20
                          ? t.gold
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Location meta row ─────────────────────────────────────────────────────────

class _LocationMeta extends StatelessWidget {
  final PintTheme t;
  final String locationText;
  final String locationHint;

  const _LocationMeta({
    required this.t,
    required this.locationText,
    required this.locationHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: _MetaRow(
        t: t,
        icon: Icons.location_on_outlined,
        label: 'ORT',
        value: locationText,
        hint: locationHint,
      ),
    );
  }
}

// ── Star rating row ───────────────────────────────────────────────────────────

class _StarRatingRow extends StatelessWidget {
  final int? rating;
  final bool enabled;
  final ValueChanged<int?> onRate;

  const _StarRatingRow({
    required this.rating,
    required this.enabled,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 14,
            color: Color(0x8CFFFFFF),
          ),
          const SizedBox(width: 10),
          const Text(
            'BEWERTUNG',
            style: TextStyle(
              color: Color(0x8CFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'optional',
            style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 11),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = rating != null && i < rating!;
              return GestureDetector(
                onTap: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onRate(rating == i + 1 ? null : i + 1);
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 24,
                    color: filled
                        ? const Color(0xFFF6B733)
                        : const Color(0x4DFFFFFF),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Drink quick-pick strip ────────────────────────────────────────────────────

class _DrinkQuickPick extends StatelessWidget {
  final PintTheme t;
  final DrinkModel? selected;
  final ValueChanged<DrinkModel>? onSelect;
  final VoidCallback? onMore;

  const _DrinkQuickPick({
    required this.t,
    required this.selected,
    this.onSelect,
    this.onMore,
  });

  static const _picks = [
    DrinkModel(
      id: '__bier',
      name: 'Bier',
      emoji: '🍺',
      isDefault: true,
      isCustom: false,
    ),
    DrinkModel(
      id: '__weizen',
      name: 'Weizen',
      emoji: '🍺',
      isDefault: true,
      isCustom: false,
    ),
    DrinkModel(
      id: '__radler',
      name: 'Radler',
      emoji: '🍋',
      isDefault: true,
      isCustom: false,
    ),
    DrinkModel(
      id: '__cocktail',
      name: 'Cocktail',
      emoji: '🍸',
      isDefault: true,
      isCustom: false,
    ),
    DrinkModel(
      id: '__wein',
      name: 'Wein',
      emoji: '🍷',
      isDefault: true,
      isCustom: false,
    ),
    DrinkModel(
      id: '__shot',
      name: 'Shot',
      emoji: '🥃',
      isDefault: true,
      isCustom: false,
    ),
  ];

  bool _isMatch(DrinkModel pick) {
    if (selected == null) return false;
    return selected!.id == pick.id ||
        selected!.name.toLowerCase() == pick.name.toLowerCase();
  }

  bool get _customSelected => selected != null && !_picks.any(_isMatch);

  @override
  Widget build(BuildContext context) {
    final customSelected = _customSelected;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: t.goldFaint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Icon(
                    Icons.local_bar_outlined,
                    color: t.gold,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'GETRÄNK',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                if (customSelected) ...[
                  _DrinkChip(
                    t: t,
                    emoji: selected!.emoji.isNotEmpty ? selected!.emoji : '🍺',
                    name: selected!.name,
                    selected: true,
                    onTap: onMore,
                  ),
                  const SizedBox(width: 6),
                ],
                for (int i = 0; i < _picks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _DrinkChip(
                    t: t,
                    emoji: _picks[i].emoji,
                    name: _picks[i].name,
                    selected: _isMatch(_picks[i]),
                    onTap: onSelect != null ? () => onSelect!(_picks[i]) : null,
                  ),
                ],
                const SizedBox(width: 6),
                _DrinkChip(
                  t: t,
                  emoji: '',
                  name: 'Mehr',
                  selected: false,
                  onTap: onMore,
                  isMore: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrinkChip extends StatelessWidget {
  final PintTheme t;
  final String emoji;
  final String name;
  final bool selected;
  final VoidCallback? onTap;
  final bool isMore;

  const _DrinkChip({
    required this.t,
    required this.emoji,
    required this.name,
    required this.selected,
    this.onTap,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.gold : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? t.gold : const Color(0x14FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMore) ...[
              Icon(
                Icons.add_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 13,
              ),
              const SizedBox(width: 4),
            ] else if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: TextStyle(
                color: selected
                    ? t.goldInk
                    : isMore
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String label;
  final String value;
  final String hint;

  const _MetaRow({
    required this.t,
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: t.goldFaint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.goldBorder),
            ),
            child: Icon(icon, color: t.gold, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x1AFFFFFF),
        ),
        child: Center(child: child),
      ),
    );
  }
}
