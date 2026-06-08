import 'package:flutter/material.dart';
import '../features/achievements/models/achievement.dart';
import '../theme.dart';
import 'shimmer_box.dart';

IconData achievementBadgeIcon(String icon) {
  return switch (icon) {
    'globe' => Icons.public,
    'century' => Icons.sports_bar_outlined,
    'streak' => Icons.bolt,
    'trophy' => Icons.emoji_events_outlined,
    'podium' => Icons.emoji_events_outlined,
    'explorer' => Icons.location_on_outlined,
    'magnet' => Icons.auto_awesome,
    'owl' => Icons.nightlight_round,
    'crown' => Icons.workspace_premium,
    'first' => Icons.sports_bar_outlined,
    _ => Icons.sports_bar_outlined,
  };
}

String achievementStatusLabel(Achievement achievement) {
  if (achievement.statusLabel.isNotEmpty) return achievement.statusLabel;
  final goal = achievement.goal <= 0 ? 1 : achievement.goal;
  if (!achievement.earned) {
    final remaining = (goal - achievement.have).clamp(0, goal);
    return 'Noch $remaining · ${achievement.have.clamp(0, goal)}/$goal';
  }
  final earnedDate = achievement.earnedDate;
  if (earnedDate == null) return 'Erhalten';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final earnedDay = DateTime(earnedDate.year, earnedDate.month, earnedDate.day);
  final days = today.difference(earnedDay).inDays;
  if (days <= 0) return 'Erhalten · heute';
  if (days == 1) return 'Erhalten · gestern';
  if (days < 7) return 'Erhalten · vor ${days}T';
  if (days < 56) return 'Erhalten · vor ${(days / 7).floor()}W';
  return 'Erhalten';
}

// ── Strip ─────────────────────────────────────────────────────────────────────

class AchievementStrip extends StatefulWidget {
  final List<Achievement> achievements;
  final bool loading;
  final PintTheme t;

  const AchievementStrip({
    super.key,
    required this.achievements,
    required this.loading,
    required this.t,
  });

  @override
  State<AchievementStrip> createState() => _AchievementStripState();
}

class _AchievementStripState extends State<AchievementStrip> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final achievements = widget.achievements;
    final earnedCount = achievements.where((a) => a.earned).length;
    final selected = achievements
        .where((a) => a.id == _selectedId)
        .cast<Achievement?>()
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                'ERFOLGE',
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.76,
                ),
              ),
              const Spacer(),
              if (achievements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: t.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 12,
                        color: t.goldText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$earnedCount von ${achievements.length}',
                        style: TextStyle(
                          color: t.goldText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.loading && achievements.isEmpty)
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, __) => SizedBox(
                width: 78,
                child: Column(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 10,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (achievements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Noch keine Erfolge.',
              style: TextStyle(color: t.textMuted, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final achievement = achievements[i];
                return AchievementBadgeMedal(
                  achievement: achievement,
                  t: t,
                  selected: achievement.id == _selectedId,
                  onTap: () => setState(() {
                    _selectedId =
                        _selectedId == achievement.id ? null : achievement.id;
                  }),
                );
              },
            ),
          ),
        if (selected != null)
          AchievementDetailCard(achievement: selected, t: t),
      ],
    );
  }
}

// ── Badge medal ───────────────────────────────────────────────────────────────

class AchievementBadgeMedal extends StatelessWidget {
  final Achievement achievement;
  final PintTheme t;
  final bool selected;
  final VoidCallback onTap;

  const AchievementBadgeMedal({
    super.key,
    required this.achievement,
    required this.t,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    final goal = achievement.goal <= 0 ? 1 : achievement.goal;
    final progress = earned
        ? 1.0
        : (achievement.have / goal).clamp(0.0, 1.0).toDouble();
    final locked = !earned && achievement.have == 0;
    final iconColor = earned ? t.goldInk : (locked ? t.textFaint : t.goldText);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BadgeRingPainter(
                        background: t.surfaceWeak,
                        progress: locked ? 0 : progress,
                        progressColor: t.gold,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: earned ? t.gold : t.surfaceWeaker,
                          border: earned
                              ? null
                              : Border.all(
                                  color: locked ? t.border : t.goldBorder,
                                ),
                          boxShadow: earned
                              ? [
                                  BoxShadow(
                                    color: t.goldStrong,
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        foregroundDecoration: selected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: t.gold, width: 2),
                              )
                            : null,
                        child: Opacity(
                          opacity: locked ? 0.6 : 1,
                          child: Icon(
                            achievementBadgeIcon(achievement.icon),
                            size: 27,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (earned)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: t.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.bg, width: 2),
                        ),
                        child: Icon(Icons.check, size: 12, color: t.goldInk),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 25,
              child: Text(
                achievement.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: locked ? t.textFaint : t.text,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            if (!earned) ...[
              const SizedBox(height: 3),
              SizedBox(
                height: 14,
                child: Text(
                  '${achievement.have.clamp(0, goal)}/$goal',
                  style: TextStyle(
                    color: locked ? t.textFaint : t.goldText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────

class AchievementDetailCard extends StatelessWidget {
  final Achievement achievement;
  final PintTheme t;

  const AchievementDetailCard({
    super.key,
    required this.achievement,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    final goal = achievement.goal <= 0 ? 1 : achievement.goal;
    final progress = (achievement.have / goal).clamp(0.0, 1.0).toDouble();
    final statusLabel = achievementStatusLabel(achievement);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: earned ? t.goldFaint : t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: earned ? t.goldBorder : t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                achievementBadgeIcon(achievement.icon),
                size: 16,
                color: t.goldText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.name,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (earned)
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            achievement.blurb,
            style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.4),
          ),
          if (!earned) ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: t.surfaceWeak,
                valueColor: AlwaysStoppedAnimation<Color>(t.gold),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusLabel,
              style: TextStyle(
                color: t.textFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _BadgeRingPainter extends CustomPainter {
  final Color background;
  final Color progressColor;
  final double progress;

  const _BadgeRingPainter({
    required this.background,
    required this.progressColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4.5;
    final backgroundPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57079632679,
        6.28318530718 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BadgeRingPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progress != progress;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
