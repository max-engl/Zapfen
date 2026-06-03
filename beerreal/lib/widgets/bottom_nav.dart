import 'package:flutter/material.dart';
import '../theme.dart';

enum PintScreen { feed, map, friends, profile }

class PintBottomNav extends StatelessWidget {
  final PintScreen current;
  final ValueChanged<PintScreen> onSelect;
  final VoidCallback onCapture;

  const PintBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _Tab(
                icon: Icons.grid_view_outlined,
                label: 'Feed',
                active: current == PintScreen.feed,
                onTap: () => onSelect(PintScreen.feed),
              ),
              _Tab(
                icon: Icons.map_outlined,
                label: 'Karte',
                active: current == PintScreen.map,
                onTap: () => onSelect(PintScreen.map),
              ),
              _CaptureTab(onTap: onCapture),
              _Tab(
                icon: Icons.people_outline,
                label: 'Freunde',
                active: current == PintScreen.friends,
                onTap: () => onSelect(PintScreen.friends),
              ),
              _Tab(
                icon: Icons.person_outline,
                label: 'Ich',
                active: current == PintScreen.profile,
                onTap: () => onSelect(PintScreen.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated tab ─────────────────────────────────────────────────────────────

class _Tab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 150),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.82,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final color = widget.active ? t.text : t.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated centre capture button ───────────────────────────────────────────

class _CaptureTab extends StatefulWidget {
  final VoidCallback onTap;

  const _CaptureTab({required this.onTap});

  @override
  State<_CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<_CaptureTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 150),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.82,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 24, color: t.goldText),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Zapfen',
                style: TextStyle(
                  color: t.goldText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
