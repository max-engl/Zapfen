import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../theme.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/services/post_service.dart';
import '../widgets/pint_loading.dart';
import 'post_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;
  String? _error;
  FeedPost? _selected;
  ll.LatLng? _deviceLocation;
  bool _locationPermissionDenied = false;
  bool _showHeatmap = true;

  final _mapController = MapController();
  final _rebuildStream = StreamController<void>.broadcast();
  StreamSubscription<Position>? _locationSub;

  static const _fallbackCenter = ll.LatLng(48.8566, 2.3522);
  static const _defaultZoom = 14.5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController.dispose();
    _rebuildStream.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final postsResult = context.read<PostService>().getMapPosts();
      await _startLocationTracking();
      final posts = await postsResult;
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
      _rebuildStream.add(null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Karte konnte nicht geladen werden';
        _loading = false;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationPermissionDenied = true);
        return;
      }

      // Get an immediate fix first
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(
          () => _deviceLocation = ll.LatLng(pos.latitude, pos.longitude),
        );
      }

      // Then stream continuous updates
      _locationSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            if (!mounted) return;
            setState(
              () => _deviceLocation = ll.LatLng(pos.latitude, pos.longitude),
            );
          });
    } catch (_) {
      // location optional — silently skip
    }
  }

  void _goToMyLocation() {
    if (_deviceLocation != null) {
      _mapController.move(_deviceLocation!, _defaultZoom);
    }
  }

  ll.LatLng get _initialCenter => _deviceLocation ?? _fallbackCenter;

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);

    if (_loading) {
      return const Center(child: PintLogoLoaderInline(size: 56));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40, color: t.textMuted),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: t.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Erneut versuchen',
                  style: TextStyle(
                    color: t.goldInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _defaultZoom,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: t.isDark
                  ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                  : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zapfen.app',
            ),
            if (_showHeatmap &&
                _posts.any((p) => p.lat != null && p.lng != null))
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(
                  data: _posts
                      .where((p) => p.lat != null && p.lng != null)
                      .map((p) => WeightedLatLng(ll.LatLng(p.lat!, p.lng!), 1))
                      .toList(),
                ),
                heatMapOptions: HeatMapOptions(
                  gradient: {
                    0.4: Colors.amber,
                    0.65: Colors.orange,
                    1.0: Colors.deepOrange,
                  },
                  layerOpacity: 0.85,
                  minOpacity: 0.2,
                  radius: 80,
                  blurFactor: 0.8,
                ),
                reset: _rebuildStream.stream,
              ),
            MarkerLayer(
              markers: [
                // User location dot
                if (_deviceLocation != null)
                  Marker(
                    point: _deviceLocation!,
                    width: 20,
                    height: 20,
                    child: _UserDot(),
                  ),
                // Post pins
                ..._posts.map(
                  (post) => Marker(
                    point: ll.LatLng(post.lat!, post.lng!),
                    width: 110,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    rotate: true,
                    child: _PostPin(
                      post: post,
                      t: t,
                      selected: _selected?.id == post.id,
                      onTap: () => setState(() => _selected = post),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Heatmap toggle button
        Positioned(
          right: 14,
          top: 64,
          child: GestureDetector(
            onTap: () => setState(() => _showHeatmap = !_showHeatmap),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _showHeatmap ? t.gold : t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _showHeatmap ? t.gold : t.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: _showHeatmap ? t.goldInk : t.textMuted,
              ),
            ),
          ),
        ),

        // Locate-me button
        Positioned(
          right: 14,
          top: 14,
          child: GestureDetector(
            onTap: _locationPermissionDenied ? null : _goToMyLocation,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: t.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location_rounded,
                size: 20,
                color: _deviceLocation != null ? t.gold : t.textMuted,
              ),
            ),
          ),
        ),

        if (_posts.isEmpty)
          Positioned(
            left: 32,
            right: 32,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: t.surface.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: t.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('😢', style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    'Noch keine Biere auf der Karte.',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Beiträge deiner Freunde erscheinen hier,\nsobald sie ihren Standort teilen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        if (_selected != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 100,
            child: _PostCard(
              post: _selected!,
              t: t,
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: _selected!),
                ),
              ),
              onDismiss: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

// ── User location dot ─────────────────────────────────────────────────────────

class _UserDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x334A90E2), blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pin ───────────────────────────────────────────────────────────────────────

class _PostPin extends StatelessWidget {
  final FeedPost post;
  final PintTheme t;
  final bool selected;
  final VoidCallback onTap;

  const _PostPin({
    required this.post,
    required this.t,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? t.gold : t.pinBg;
    final fg = selected ? t.goldInk : Colors.white;
    final borderColor = selected ? Colors.white : t.gold;
    final arrowColor = selected ? Colors.white : t.gold;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: selected ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_bar_outlined,
                    size: 11,
                    color: selected ? t.goldInk : t.gold,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      post.username,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(10, 7),
              painter: _Arrow(color: arrowColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends CustomPainter {
  final Color color;
  const _Arrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Arrow old) => old.color != color;
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final FeedPost post;
  final PintTheme t;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const _PostCard({
    required this.post,
    required this.t,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: post.imageUrl.isNotEmpty
                  ? Image.network(
                      post.imageUrl,
                      width: 60,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 72,
                        color: t.surfaceWeak,
                      ),
                    )
                  : Container(width: 60, height: 72, color: t.surfaceWeak),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.username,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (post.caption.isNotEmpty)
                    Text(
                      post.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textMuted, fontSize: 13),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 11,
                        color: t.textFaint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: t.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.sports_bar_outlined, size: 11, color: t.gold),
                      const SizedBox(width: 3),
                      Text(
                        '${post.likes}',
                        style: TextStyle(
                          color: t.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceWeak,
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(Icons.close, size: 14, color: t.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ansehen',
                    style: TextStyle(
                      color: t.goldInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
