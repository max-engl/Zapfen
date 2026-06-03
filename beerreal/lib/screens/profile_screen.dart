import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart'
    show FullscreenImageViewer;
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../theme.dart';
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
