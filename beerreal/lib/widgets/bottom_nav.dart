import 'package:flutter/material.dart';
import '../theme.dart';

enum PintScreen { feed, map, friends, profile }

class PintBottomNav extends StatelessWidget {
  final PintScreen current;
  final ValueChanged<PintScreen> onSelect;
  final VoidCallback onCapture;
  final int pendingRequests;

  const PintBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onCapture,
    this.pendingRequests = 0,
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
                activeIcon: Icons.grid_view,
                label: 'Feed',
                active: current == PintScreen.feed,
                onTap: () => onSelect(PintScreen.feed),
              ),
              _Tab(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Karte',
                active: current == PintScreen.map,
                onTap: () => onSelect(PintScreen.map),
              ),
              _CaptureTab(onTap: onCapture),
              _Tab(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Freunde',
                active: current == PintScreen.friends,
                onTap: () => onSelect(PintScreen.friends),
                badge: pendingRequests > 0,
              ),
              _Tab(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
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
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool badge;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = false,
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
    final labelColor = widget.active ? t.goldText : t.textMuted;
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.active ? t.goldSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        widget.active ? widget.activeIcon : widget.icon,
                        key: ValueKey(widget.active),
                        size: 22,
                        color: widget.active ? t.goldText : t.textMuted,
                      ),
                    ),
                    if (widget.badge)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: t.gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.bg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                ),
                child: Text(widget.label),
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
              Icon(Icons.camera_alt_outlined, size: 22, color: t.goldText),
              const SizedBox(height: 2),
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
