import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart'
    show FullscreenImageViewer;
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../theme.dart';
import '../features/achievements/models/achievement.dart';
import '../features/achievements/providers/achievement_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/providers/profile_posts_provider.dart';
import '../features/profile/services/profile_service.dart';
import '../widgets/avatar.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/stagger_item.dart';
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';

DateTime _cellIndexToDay(int cellIndex) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: 83 - cellIndex));
}

List<FeedPost> _postsForCell(List<FeedPost> posts, int? selectedCell) {
  if (selectedCell == null) return posts.take(12).toList();
  final day = _cellIndexToDay(selectedCell);
  return posts.where((p) {
    final d = DateTime(p.createdAt.year, p.createdAt.month, p.createdAt.day);
    return d == day;
  }).toList();
}

class ProfileScreen extends StatefulWidget {
  final bool standaloneRoute;
  const ProfileScreen({super.key, this.standaloneRoute = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  int? _selectedCell;
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilePostsProvider>().load();
      context.read<AchievementProvider>().load();
      _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Animation<double> _statAnim(int index) {
    const stagger = 0.15;
    const animSpan = 0.55;
    final start = stagger * index;
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(
        start,
        (start + animSpan).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final user = context.watch<AuthProvider>().user;
    final pp = context.watch<ProfilePostsProvider>();
    final achievements = context.watch<AchievementProvider>();
    final grid = pp.heatmapGrid;

    final body = GestureDetector(
      onTap: () => setState(() => _selectedCell = null),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: (user?.avatarUrl?.isNotEmpty ?? false)
                      ? () => FullscreenImageViewer.open(
                          context: context,
                          child: CachedNetworkImage(
                            imageUrl: user!.avatarUrl!,
                            cacheManager: AppCacheManager.instance,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.black),
                          ),
                        )
                      : null,
                  child: PintAvatar(
                    size: 72,
                    ring: true,
                    imageUrl: user?.avatarUrl,
                    avatarColor: user?.avatarColor,
                    initials: user?.avatarInitial,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? '',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user?.username ?? ''}',
                      style: TextStyle(color: t.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        profileService: context.read<ProfileService>(),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: t.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.read<AuthProvider>().logout(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(Icons.logout, size: 18, color: t.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Stats row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _AnimatedTile(
                    animation: _statAnim(0),
                    child: _StatTile(
                      value: pp.streak,
                      label: 'Serie',
                      t: t,
                      gold: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedTile(
                    animation: _statAnim(1),
                    child: _StatTile(
                      value: pp.totalPints,
                      label: 'Biere',
                      t: t,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnimatedTile(
                    animation: _statAnim(2),
                    child: _StatTile(value: pp.spots, label: 'Orte', t: t),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _AchievementStrip(provider: achievements, t: t),
          const SizedBox(height: 18),

          // ── Streak heatmap ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '12 WOCHEN',
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'weniger ',
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                    ),
                    ...List.generate(
                      4,
                      (i) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: t.streakCell[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      ' mehr',
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _HeatmapGrid(
                  grid: grid,
                  t: t,
                  selectedCell: _selectedCell,
                  onCellTap: (index) {
                    setState(() {
                      _selectedCell = _selectedCell == index ? null : index;
                    });
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: _selectedCell == null
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : _DayTooltip(
                          key: ValueKey(_selectedCell),
                          cellIndex: _selectedCell!,
                          pintCount: grid[_selectedCell!],
                          t: t,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Recent pours ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Builder(
              builder: (context) {
                final displayedPosts = _postsForCell(pp.posts, _selectedCell);
                String sectionLabel;
                if (_selectedCell == null) {
                  sectionLabel = 'LETZTE BIERE';
                } else {
                  const months = [
                    'Jan',
                    'Feb',
                    'Mär',
                    'Apr',
                    'Mai',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Okt',
                    'Nov',
                    'Dez',
                  ];
                  final d = _cellIndexToDay(_selectedCell!);
                  sectionLabel = 'BIERE · ${months[d.month - 1]} ${d.day}';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionLabel,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (pp.loading)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        children: List.generate(
                          9,
                          (_) => ShimmerBox(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else if (displayedPosts.isEmpty)
                      Text(
                        _selectedCell == null
                            ? 'Noch keine Biere.'
                            : 'Kein Bier an diesem Tag.',
                        style: TextStyle(color: t.textMuted, fontSize: 13),
                      )
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        children: List.generate(displayedPosts.length, (i) {
                          final p = displayedPosts[i];
                          final diag = (i ~/ 3) + (i % 3);
                          return DiagonalStaggerItem(
                            key: ValueKey('${p.id}_$_selectedCell'),
                            diagonalIndex: diag,
                            child: _PostThumb(
                              post: p,
                              t: t,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: p),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.standaloneRoute) {
      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(child: body),
      );
    }
    return body;
  }
}

// ── Entrance animation wrapper ────────────────────────────────────────────

class _AnimatedTile extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _AnimatedTile({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.25, -0.25),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

// ── Post thumbnail ────────────────────────────────────────────────────────

class _PostThumb extends StatelessWidget {
  final FeedPost post;
  final PintTheme t;
  final VoidCallback? onTap;
  const _PostThumb({required this.post, required this.t, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: post.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: post.imageUrl,
                cacheKey: post.imagePath ?? post.id,
                cacheManager: AppCacheManager.instance,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: t.surfaceWeak),
              )
            : Container(color: t.surfaceWeak),
      ),
    );
  }
}

class _AchievementStrip extends StatefulWidget {
  final AchievementProvider provider;
  final PintTheme t;

  const _AchievementStrip({required this.provider, required this.t});

  @override
  State<_AchievementStrip> createState() => _AchievementStripState();
}

class _AchievementStripState extends State<_AchievementStrip> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final t = widget.t;
    final achievements = provider.achievements;
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
                        '${provider.earnedCount} von ${achievements.length}',
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
        if (provider.loading && achievements.isEmpty)
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
                return _BadgeMedal(
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
        if (selected != null) _AchievementDetail(achievement: selected, t: t),
      ],
    );
  }
}

class _BadgeMedal extends StatelessWidget {
  final Achievement achievement;
  final PintTheme t;
  final bool selected;
  final VoidCallback onTap;

  const _BadgeMedal({
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
    final locked = !earned && progress < 0.05;
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
                            _badgeIcon(achievement.icon),
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
              Text(
                '${achievement.have.clamp(0, goal)}/$goal',
                style: TextStyle(
                  color: locked ? t.textFaint : t.goldText,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _badgeIcon(String icon) {
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
}

class _AchievementDetail extends StatelessWidget {
  final Achievement achievement;
  final PintTheme t;

  const _AchievementDetail({required this.achievement, required this.t});

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    final goal = achievement.goal <= 0 ? 1 : achievement.goal;
    final progress = (achievement.have / goal).clamp(0.0, 1.0).toDouble();
    final statusLabel = _statusLabel(achievement);

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
              Icon(_badgeIcon(achievement.icon), size: 16, color: t.goldText),
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

  IconData _badgeIcon(String icon) {
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

  String _statusLabel(Achievement achievement) {
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
    final earnedDay = DateTime(
      earnedDate.year,
      earnedDate.month,
      earnedDate.day,
    );
    final days = today.difference(earnedDay).inDays;
    if (days <= 0) return 'Erhalten · heute';
    if (days == 1) return 'Erhalten · gestern';
    if (days < 7) return 'Erhalten · vor ${days}T';
    if (days < 56) return 'Erhalten · vor ${(days / 7).floor()}W';
    return 'Erhalten';
  }
}

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
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

// ── Heatmap grid ──────────────────────────────────────────────────────────

class _HeatmapGrid extends StatefulWidget {
  final List<int> grid;
  final PintTheme t;
  final int? selectedCell;
  final ValueChanged<int> onCellTap;

  const _HeatmapGrid({
    required this.grid,
    required this.t,
    required this.selectedCell,
    required this.onCellTap,
  });

  @override
  State<_HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends State<_HeatmapGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // 12 cols, 7 rows → max diagonal = 11 + 6 = 17
  static const _cols = 12;
  static const _rows = 7;
  static const _maxDiag = _cols - 1 + _rows - 1; // 17
  static const _cellAnimMs = 280;
  static const _staggerMs = 22;
  static const _totalMs = _cellAnimMs + _staggerMs * _maxDiag; // ~654ms

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _cellAnim(int col, int row) {
    final diag = col + row;
    final start = (_staggerMs * diag) / _totalMs;
    final end = (_staggerMs * diag + _cellAnimMs) / _totalMs;
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.t.borderWeak),
      ),
      child: Row(
        children: List.generate(_cols, (col) {
          return Expanded(
            child: Column(
              children: List.generate(_rows, (row) {
                final index = col * _rows + row;
                final v = widget.grid[index];
                final isSelected = widget.selectedCell == index;
                final anim = _cellAnim(col, row);
                return GestureDetector(
                  onTap: () => widget.onCellTap(index),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedBuilder(
                      animation: anim,
                      builder: (_, child) => Opacity(
                        opacity: anim.value,
                        child: Transform.translate(
                          offset: Offset(
                            -6 * (1 - anim.value),
                            -6 * (1 - anim.value),
                          ),
                          child: child,
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (widget.t.isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF))
                              : widget.t.streakCell[v.clamp(
                                  0,
                                  widget.t.streakCell.length - 1,
                                )],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ── Day tooltip ───────────────────────────────────────────────────────────

class _DayTooltip extends StatelessWidget {
  final int cellIndex;
  final int pintCount;
  final PintTheme t;

  const _DayTooltip({
    super.key,
    required this.cellIndex,
    required this.pintCount,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final daysAgo = 83 - cellIndex;
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const monthNames = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    final label =
        '${dayNames[date.weekday - 1]} · ${monthNames[date.month - 1]} ${date.day}';
    final pintLabel = pintCount == 0
        ? 'kein Bier'
        : pintCount == 1
        ? '1 Bier'
        : '$pintCount Biere';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: pintCount > 0 ? t.goldFaint : t.surfaceWeak,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: pintCount > 0 ? t.goldBorder : t.border,
              ),
            ),
            child: Icon(
              pintCount > 0
                  ? Icons.sports_bar_outlined
                  : Icons.sports_bar_rounded,
              size: 15,
              color: pintCount > 0 ? t.goldText : t.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            pintLabel,
            style: TextStyle(
              color: pintCount > 0 ? t.text : t.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: t.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final PintTheme t;
  final bool gold;

  const _StatTile({
    required this.value,
    required this.label,
    required this.t,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: gold ? t.goldFaint : t.surfaceWeaker,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold ? t.goldBorder : t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: gold ? t.goldText : t.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
