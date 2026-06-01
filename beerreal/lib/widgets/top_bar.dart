import 'package:flutter/material.dart';
import '../theme.dart';
import 'brand_mark.dart';

class PintTopBar extends StatelessWidget {
  final VoidCallback onBell;
  final VoidCallback onToggleTheme;
  final VoidCallback onLeaderboard;
  final int unreadNotifications;

  const PintTopBar({
    super.key,
    required this.onBell,
    required this.onToggleTheme,
    required this.onLeaderboard,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          // Brand
          const BrandMark(size: 30),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Zapfen',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.66,
                  ),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Leaderboard
          _IconBtn(
            icon: Icons.emoji_events_rounded,
            color: t.goldText,
            bg: t.goldFaint,
            border: t.goldBorder,
            onTap: onLeaderboard,
          ),
          const SizedBox(width: 8),
          // Theme toggle
          _IconBtn(
            icon: t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: t.text,
            bg: t.surfaceWeak,
            border: t.border,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 8),
          // Bell with optional unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.notifications_outlined,
                color: t.text,
                bg: t.surfaceWeak,
                border: t.border,
                onTap: onBell,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: t.gold,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.bg, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                        style: TextStyle(
                          color: t.goldInk,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
