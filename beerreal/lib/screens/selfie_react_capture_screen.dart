import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../theme.dart';
import '../widgets/pint_loading.dart';

// Runs in a background isolate — flips a JPEG image horizontally.
Uint8List _flipJpegHorizontal(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  return Uint8List.fromList(
    img.encodeJpg(img.flipHorizontal(decoded), quality: 92),
  );
}

enum _Stage { initializing, aim, flash, review }

/// BeReal-style circular front-camera capture flow for reacting to a post
/// with a selfie. Mirrors the design in selfieui/app (3).jsx exactly:
/// aim → flash → review, with a 268×268 gold-ringed circular frame.
class SelfieReactCaptureScreen extends StatefulWidget {
  final Future<void> Function(Uint8List bytes) onSend;

  const SelfieReactCaptureScreen({super.key, required this.onSend});

  @override
  State<SelfieReactCaptureScreen> createState() =>
      _SelfieReactCaptureScreenState();
}

class _SelfieReactCaptureScreenState extends State<SelfieReactCaptureScreen>
    with SingleTickerProviderStateMixin {
  _Stage _stage = _Stage.initializing;
  String? _initError;
  CameraController? _frontCtrl;
  Uint8List? _shotBytes;
  bool _capturing = false;
  bool _sending = false;
  String? _sendError;
  late final AnimationController _ringPulseCtrl;

  @override
  void initState() {
    super.initState();
    _ringPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _ringPulseCtrl.dispose();
    _frontCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        frontDesc,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      await ctrl.setFlashMode(FlashMode.off);
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _frontCtrl = ctrl;
        _stage = _Stage.aim;
      });
    } catch (_) {
      if (mounted) setState(() => _initError = 'Kamera nicht verfügbar');
    }
  }

  Future<void> _shutter() async {
    final ctrl = _frontCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_stage != _Stage.aim || _capturing) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _capturing = true;
      _sendError = null;
    });
    try {
      final file = await ctrl.takePicture();
      final raw = await file.readAsBytes();
      final flipped = await compute(_flipJpegHorizontal, raw);
      if (!mounted) return;
      setState(() {
        _shotBytes = flipped;
        _stage = _Stage.flash;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _stage = _Stage.review;
        _capturing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _retake() {
    HapticFeedback.selectionClick();
    setState(() {
      _shotBytes = null;
      _sendError = null;
      _stage = _Stage.aim;
    });
  }

  Future<void> _send() async {
    final bytes = _shotBytes;
    if (bytes == null || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await widget.onSend(bytes);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendError = 'Senden fehlgeschlagen. Bitte erneut versuchen.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: _stage == _Stage.initializing ? _buildInit(t) : _buildCapture(t),
      ),
    );
  }

  Widget _buildInit(PintTheme t) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _TopBar(t: t, onClose: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: _initError != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _initError!,
                        style: const TextStyle(
                          color: Color(0x8CFFFFFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() => _initError = null);
                          _initCamera();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Erneut versuchen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const PintLogoLoaderInline(size: 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCapture(PintTheme t) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _TopBar(t: t, onClose: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _ringPulseCtrl,
                    builder: (_, child) => _Circle(
                      t: t,
                      pulse: _stage == _Stage.aim ? _ringPulseCtrl.value : 0,
                      review: _stage == _Stage.review,
                      child: child!,
                    ),
                    child: _buildCircleContent(t),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 240,
                    child: Text(
                      _stage == _Stage.review
                          ? 'Sieht gut aus — Reaktion senden'
                          : 'Tippe den Auslöser, um mit einem Selfie zu reagieren',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (_sendError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _sendError!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 44),
          child: Center(child: _buildControls(t)),
        ),
      ],
    );
  }

  Widget _buildCircleContent(PintTheme t) {
    final showShot = _stage == _Stage.review && _shotBytes != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: showShot
              ? _ReviewShot(bytes: _shotBytes!)
              : _frontCtrl != null && _frontCtrl!.value.isInitialized
              ? _CamFill(ctrl: _frontCtrl!)
              : const ColoredBox(color: Colors.black),
        ),
        if (_stage == _Stage.flash)
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
        if (_capturing && _stage == _Stage.aim)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(PintTheme t) {
    if (_stage == _Stage.review) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BouncyControl(
            onTap: _sending ? null : _retake,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 28),
          _BouncyControl(
            onTap: _sending ? null : _send,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: t.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _sending
                  ? SizedBox(
                      height: 16,
                      child: PintDots(color: t.goldInk, dotSize: 6, spacing: 5),
                    )
                  : Text(
                      'Reaktion senden',
                      style: TextStyle(
                        color: t.goldInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.16,
                      ),
                    ),
            ),
          ),
        ],
      );
    }
    return _ShutterButton(onTap: _shutter, capturing: _capturing, t: t);
  }
}

class _ReviewShot extends StatelessWidget {
  final Uint8List bytes;
  const _ReviewShot({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('review-shot'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Transform.scale(
        scale: 0.88 + 0.12 * value,
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: SizedBox.expand(child: Image.memory(bytes, fit: BoxFit.cover)),
    );
  }
}

class _BouncyControl extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _BouncyControl({required this.onTap, required this.child});

  @override
  State<_BouncyControl> createState() => _BouncyControlState();
}

class _BouncyControlState extends State<_BouncyControl> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool capturing;
  final PintTheme t;

  const _ShutterButton({
    required this.onTap,
    required this.capturing,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return _BouncyControl(
      onTap: capturing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
        width: capturing ? 76 : 84,
        height: capturing ? 76 : 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: Colors.white.withValues(alpha: capturing ? 0.65 : 1),
            width: capturing ? 3 : 4,
          ),
        ),
        padding: EdgeInsets.all(capturing ? 10 : 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutBack,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: capturing ? Colors.white : t.gold,
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final PintTheme t;
  final VoidCallback onClose;
  const _TopBar({required this.t, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.face_retouching_natural_outlined,
                size: 13,
                color: t.gold,
              ),
              const SizedBox(width: 6),
              Text(
                'SELFIE-REAKTION',
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
    );
  }
}

// ── Gold-ringed circular frame ────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final Widget child;
  final PintTheme t;
  final double pulse;
  final bool review;
  const _Circle({
    required this.child,
    required this.t,
    required this.pulse,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: review ? 1.035 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: Container(
        width: 268,
        height: 268,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: t.gold, width: 3 + pulse * 1.4),
          boxShadow: [
            BoxShadow(
              color: t.gold.withValues(alpha: 0.18 + pulse * 0.16),
              blurRadius: 24 + pulse * 18,
              spreadRadius: pulse * 2,
            ),
            const BoxShadow(
              color: Color(0x99000000),
              blurRadius: 50,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}

// ── Camera preview fill (matches capture_screen.dart's _CamFill) ───────────

class _CamFill extends StatelessWidget {
  final CameraController ctrl;
  const _CamFill({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (!ctrl.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitAspect = 1 / ctrl.value.aspectRatio;
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / portraitAspect,
                child: CameraPreview(ctrl),
              ),
            ),
          ),
        );
      },
    );
  }
}
