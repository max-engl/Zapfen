import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../theme.dart';
import '../features/friends/models/api_friend.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/services/post_service.dart';
import '../features/posts/providers/feed_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_box.dart';
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

class FriendProfileScreen extends StatefulWidget {
  final ApiFriend friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;
  int? _selectedCell;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await context.read<PostService>().getUserPosts(
        widget.friend.id,
      );
      if (mounted) setState(() => _posts = posts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final grid = buildHeatmapFromPosts(_posts);
    final feed = context.watch<FeedProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _selectedCell = null),
          behavior: HitTestBehavior.translucent,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 18, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: t.text,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Row(
                  children: [
                    PintAvatar(
                      size: 72,
                      ring: true,
                      imageUrl: widget.friend.avatarUrl,
                      avatarColor: widget.friend.avatarColor,
                      initials: widget.friend.avatarInitial,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friend.username,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${widget.friend.username}',
                          style: TextStyle(color: t.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Stats ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _StatTile(value: _posts.length, label: 'Biere', t: t),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Heatmap ──
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
                    _loading
                        ? Container(
                            height: 80,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const ShimmerBox(),
                          )
                        : _HeatmapGrid(
                            grid: grid,
                            t: t,
                            selectedCell: _selectedCell,
                            onCellTap: (index) => setState(() {
                              _selectedCell = _selectedCell == index
                                  ? null
                                  : index;
                            }),
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
                    final displayedPosts = _postsForCell(_posts, _selectedCell);
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
                        if (_loading)
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
                            children: displayedPosts
                                .map(
                                  (p) => _PostThumb(
                                    post: p,
                                    t: t,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(post: p),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Their posts in feed ──
              if (_posts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Text(
                    'IHRE BIERE',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                ..._posts.map(
                  (p) => PostCard(
                    key: ValueKey(p.id),
                    post: p,
                    onReact: (emoji) => feed.toggleReaction(p.id, emoji),
                    onTap: () {
                      debugPrint(
                        '[FriendFeed] tapped post ${p.id} by ${p.username}',
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: p),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
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

class _HeatmapGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderWeak),
      ),
      child: Row(
        children: List.generate(12, (col) {
          return Expanded(
            child: Column(
              children: List.generate(7, (row) {
                final index = col * 7 + row;
                final v = grid[index];
                final isSelected = selectedCell == index;
                return GestureDetector(
                  onTap: () => onCellTap(index),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (t.isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF))
                            : t.streakCell[v.clamp(0, t.streakCell.length - 1)],
                        borderRadius: BorderRadius.circular(3),
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

  const _StatTile({required this.value, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: t.surfaceWeaker,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: t.text,
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
      ),
    );
  }
}
