import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/achievements/models/achievement.dart';
import '../features/achievements/services/achievement_service.dart';
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
    'secret' => Icons.lock_outline_rounded,
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
                    _selectedId = _selectedId == achievement.id
                        ? null
                        : achievement.id;
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
    final mystery = achievement.hidden && !earned;
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
                mystery ? '???' : achievement.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mystery
                      ? t.textFaint
                      : locked
                      ? t.textFaint
                      : t.text,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            if (!earned && !mystery) ...[
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

class AchievementDetailCard extends StatefulWidget {
  final Achievement achievement;
  final PintTheme t;

  const AchievementDetailCard({
    super.key,
    required this.achievement,
    required this.t,
  });

  @override
  State<AchievementDetailCard> createState() => _AchievementDetailCardState();
}

class _AchievementDetailCardState extends State<AchievementDetailCard> {
  bool _showFriends = false;
  bool _loadingFriends = false;
  List<FriendAchievementStanding>? _standings;

  @override
  void didUpdateWidget(AchievementDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.achievement.id != widget.achievement.id) {
      setState(() {
        _showFriends = false;
        _standings = null;
        _loadingFriends = false;
      });
    }
  }

  Future<void> _toggleFriends() async {
    if (_showFriends) {
      setState(() => _showFriends = false);
      return;
    }
    setState(() => _showFriends = true);
    if (_standings != null) return;
    setState(() => _loadingFriends = true);
    try {
      final standings = await context
          .read<AchievementService>()
          .fetchFriendStandings(widget.achievement.id);
      if (mounted) {
        setState(() {
          _standings = standings;
          _loadingFriends = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _standings = [];
          _loadingFriends = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final t = widget.t;
    final earned = achievement.earned;
    final mystery = achievement.hidden && !earned;
    final goal = achievement.goal <= 0 ? 1 : achievement.goal;
    final progress = (achievement.have / goal).clamp(0.0, 1.0).toDouble();
    final statusLabel = achievementStatusLabel(achievement);
    final showFriendsButton = !mystery;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: mystery
            ? t.surfaceWeaker
            : earned
            ? t.goldFaint
            : t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mystery
              ? t.border
              : earned
              ? t.goldBorder
              : t.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                mystery
                    ? Icons.lock_outline_rounded
                    : achievementBadgeIcon(achievement.icon),
                size: 16,
                color: mystery ? t.textFaint : t.goldText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mystery ? 'Geheimes Achievement' : achievement.name,
                  style: TextStyle(
                    color: mystery ? t.textMuted : t.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (earned && !mystery)
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
            mystery
                ? 'Logge weiter, um dieses Achievement zu entdecken.'
                : achievement.blurb,
            style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.4),
          ),
          if (!earned && !mystery) ...[
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

          // Friends standings toggle button
          if (showFriendsButton) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _toggleFriends,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceWeaker,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: t.goldText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Wie machen sich deine Freunde?',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showFriends ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showFriends)
              _FriendStandingsList(
                standings: _standings,
                loading: _loadingFriends,
                t: t,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Friend standings list ─────────────────────────────────────────────────────

class _FriendStandingsList extends StatelessWidget {
  final List<FriendAchievementStanding>? standings;
  final bool loading;
  final PintTheme t;

  const _FriendStandingsList({
    required this.standings,
    required this.loading,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final rows = standings ?? [];
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Noch keine Freunde vorhanden.',
          style: TextStyle(
            color: t.textFaint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final selfIndex = rows.indexWhere((r) => r.isSelf);
    final selfRank = selfIndex + 1;

    // Find the leading friend (not self, earned or highest progress)
    FriendAchievementStanding? leader;
    for (final r in rows) {
      if (!r.isSelf) {
        leader = r;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DEIN KREIS',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            if (selfRank > 0)
              Text(
                'Du bist #$selfRank von ${rows.length}',
                style: TextStyle(
                  color: t.goldText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return _StandingRow(rank: i + 1, standing: r, t: t);
        }),
        // Footer note
        if (leader != null) ...[
          const SizedBox(height: 8),
          Text(
            leader.earned
                ? '${leader.username.split(' ').first} hat es schon geschafft.'
                : '${leader.username.split(' ').first} führt deinen Kreis an.',
            style: TextStyle(
              color: t.textFaint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int rank;
  final FriendAchievementStanding standing;
  final PintTheme t;

  const _StandingRow({
    required this.rank,
    required this.standing,
    required this.t,
  });

  String _earnedAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'heute';
    if (days == 1) return 'gestern';
    if (days < 7) return 'vor ${days}T';
    if (days < 56) return 'vor ${(days / 7).floor()}W';
    return 'vor längerem';
  }

  @override
  Widget build(BuildContext context) {
    final goal = standing.goal <= 0 ? 1 : standing.goal;
    final pct = standing.earned ? 1.0 : (standing.have / goal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: standing.isSelf ? t.goldFaint : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: standing.isSelf ? t.goldBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rank == 1 ? t.goldText : t.textFaint,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          _MiniAvatar(standing: standing, t: t),
          const SizedBox(width: 10),
          // Name + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.isSelf
                      ? '${standing.username} · du'
                      : standing.username,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 13,
                    fontWeight: standing.isSelf
                        ? FontWeight.w800
                        : FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: t.surfaceWeak,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      standing.earned
                          ? t.gold
                          : (standing.isSelf ? t.gold : t.goldText),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status
          if (standing.earned)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 11, color: t.goldText),
                const SizedBox(width: 3),
                Text(
                  standing.earnedDate != null
                      ? _earnedAgo(standing.earnedDate!)
                      : 'Erhalten',
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          else
            Text(
              '${standing.have}/$goal',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final FriendAchievementStanding standing;
  final PintTheme t;

  const _MiniAvatar({required this.standing, required this.t});

  @override
  Widget build(BuildContext context) {
    final url = standing.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(standing: standing),
        ),
      );
    }
    return _InitialsAvatar(standing: standing);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final FriendAchievementStanding standing;

  const _InitialsAvatar({required this.standing});

  @override
  Widget build(BuildContext context) {
    Color bg;
    try {
      final hex = standing.avatarColor.replaceFirst('#', '');
      bg = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      bg = const Color(0xFFF6B733);
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          standing.avatarInitial.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
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
