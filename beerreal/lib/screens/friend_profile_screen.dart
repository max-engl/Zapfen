import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart'
    show FullscreenImageViewer;
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../core/geocoding_service.dart';
import '../theme.dart';
import '../features/achievements/models/achievement.dart';
import '../features/achievements/services/achievement_service.dart';
import '../features/bingo/services/bingo_service.dart';
import '../features/blocks/providers/block_provider.dart';
import '../features/friends/models/api_friend.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/services/post_service.dart';
import '../features/posts/providers/feed_provider.dart';
import '../widgets/achievement_strip.dart';
import '../widgets/avatar.dart';
import '../widgets/pint_dialogs.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/stagger_item.dart';
import 'bingo_screen.dart';
import 'post_detail_screen.dart';

int _drinkLevel(int count) {
  if (count <= 0) return 0;
  if (count == 1) return 1;
  if (count <= 3) return 2;
  if (count <= 6) return 3;
  if (count <= 9) return 4;
  return 5;
}

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

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with TickerProviderStateMixin {
  List<FeedPost> _posts = [];
  bool _loading = true;
  List<Achievement> _achievements = [];
  bool _achievementsLoading = true;
  BingoCard? _bingoCard;
  bool _bingoLoading = true;
  int? _selectedCell;
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
    _loadPosts();
    _loadAchievements();
    _loadBingoCard();
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

  int get _streak {
    if (_posts.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days =
        _posts
            .map(
              (p) => DateTime(
                p.createdAt.year,
                p.createdAt.month,
                p.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (today.difference(days.first).inDays > 1) return 0;
    int count = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  List<String> get _countries {
    final set = <String>{};
    for (final p in _posts) {
      if (p.country != null && p.country!.isNotEmpty) set.add(p.country!);
    }
    return set.toList()..sort();
  }

  void _showCountries(BuildContext context, List<String> countries, PintTheme t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.goldFaint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.goldBorder),
                      ),
                      child: Icon(Icons.public_rounded, color: t.goldText, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${countries.length} ${countries.length == 1 ? 'Land' : 'Länder'}',
                          style: TextStyle(
                            color: t.text, fontSize: 16,
                            fontWeight: FontWeight.w700, letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Länder, in denen ${widget.friend.username} getrunken hat',
                          style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: countries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.surfaceWeaker,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          countries[i],
                          style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await context.read<PostService>().getUserPosts(
        widget.friend.id,
      );
      if (mounted) setState(() => _posts = posts);
      _geocodeMissingCountries();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeMissingCountries() async {
    final missing = _posts
        .where((p) => (p.country == null || p.country!.isEmpty) && p.lat != null && p.lng != null)
        .toList();
    if (missing.isEmpty) return;

    var updated = List<FeedPost>.from(_posts);
    var changed = false;
    for (final post in missing) {
      final c = await GeocodingService.countryName(post.lat!, post.lng!);
      if (c != null && c.isNotEmpty) {
        final idx = updated.indexWhere((p) => p.id == post.id);
        if (idx >= 0) {
          updated[idx] = updated[idx].copyWith(country: c);
          changed = true;
        }
      }
    }
    if (changed && mounted) setState(() => _posts = updated);
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await context
          .read<AchievementService>()
          .fetchForUser(widget.friend.id);
      if (mounted) setState(() => _achievements = achievements);
    } catch (e) {
      debugPrint('[FriendProfile] achievements error: $e');
    } finally {
      if (mounted) setState(() => _achievementsLoading = false);
    }
  }

  Future<void> _loadBingoCard() async {
    try {
      final card = await context.read<BingoService>().fetchCardForUser(
        widget.friend.id,
      );
      if (mounted) setState(() => _bingoCard = card);
    } catch (e) {
      debugPrint('[FriendProfile] bingo error: $e');
    } finally {
      if (mounted) setState(() => _bingoLoading = false);
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
                    _BlockMenuButton(userId: widget.friend.id, username: widget.friend.username, t: t),
                  ],
                ),
              ),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: (widget.friend.avatarUrl?.isNotEmpty ?? false)
                          ? () => FullscreenImageViewer.open(
                              context: context,
                              child: CachedNetworkImage(
                                imageUrl: widget.friend.avatarUrl!,
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
                        imageUrl: widget.friend.avatarUrl,
                        avatarColor: widget.friend.avatarColor,
                        initials: widget.friend.avatarInitial,
                      ),
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

              // ── Stats row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedTile(
                        animation: _statAnim(0),
                        child: _StatTile(
                          value: _streak,
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
                          value: _posts.length,
                          label: 'Drinks',
                          t: t,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnimatedTile(
                        animation: _statAnim(2),
                        child: GestureDetector(
                          onTap: _countries.isEmpty ? null : () => _showCountries(context, _countries, t),
                          child: _StatTile(value: _countries.length, label: 'Länder', t: t),
                        ),
                      ),
                    ),
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
                          6,
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

              // ── Achievements ──
              AchievementStrip(
                achievements: _achievements,
                loading: _achievementsLoading,
                t: t,
              ),
              const SizedBox(height: 18),

              // ── Bingo ──
              _FriendBingoBanner(
                card: _bingoCard,
                loading: _bingoLoading,
                t: t,
                onTap: _bingoCard == null
                    ? null
                    : () => BingoScreen.show(
                        context,
                        card: _bingoCard,
                        ownerName: widget.friend.username,
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
                            children: List.generate(displayedPosts.length, (i) {
                              final p = displayedPosts[i];
                              return DiagonalStaggerItem(
                                key: ValueKey('${p.id}_$_selectedCell'),
                                diagonalIndex: (i ~/ 3) + (i % 3),
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
                ..._posts.asMap().entries.map(
                  (e) => StaggerItem(
                    key: ValueKey(e.value.id),
                    index: e.key,
                    child: PostCard(
                      post: e.value,
                      heroTagPrefix: 'fp_',
                      onReact: (emoji) =>
                          feed.toggleReaction(e.value.id, emoji),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: e.value,
                            heroTagPrefix: 'fp_',
                          ),
                        ),
                      ),
                    ),
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

// ── Block menu button ─────────────────────────────────────────────────────

class _BlockMenuButton extends StatelessWidget {
  final String userId;
  final String username;
  final PintTheme t;

  const _BlockMenuButton({
    required this.userId,
    required this.username,
    required this.t,
  });

  Future<void> _showSheet(BuildContext context) async {
    final blockProvider = context.read<BlockProvider>();
    final isBlocked = blockProvider.isBlocked(userId);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: t.isDark ? 0.45 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.textFaint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OptionTile(
                    t: t,
                    icon: isBlocked ? Icons.person_add_outlined : Icons.block,
                    title: isBlocked ? 'Blockierung aufheben' : 'Nutzer blockieren',
                    subtitle: isBlocked
                        ? '@$username wird wieder sichtbar.'
                        : 'Beiträge von @$username ausblenden.',
                    destructive: !isBlocked,
                    onTap: () async {
                      Navigator.of(sheetCtx).pop();
                      try {
                        if (isBlocked) {
                          await blockProvider.unblockUser(userId);
                          if (context.mounted) showPintSnackBar(context, '@$username wurde entsperrt.');
                        } else {
                          await blockProvider.blockUser(userId);
                          if (context.mounted) {
                            showPintSnackBar(context, '@$username wurde blockiert.');
                            Navigator.of(context).pop();
                          }
                        }
                      } catch (_) {
                        if (context.mounted) {
                          showPintSnackBar(context, 'Aktion fehlgeschlagen.', isError: true);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _OptionTile(
                    t: t,
                    icon: Icons.close,
                    title: 'Schließen',
                    subtitle: 'Zurück zum Profil.',
                    onTap: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.more_horiz, color: t.textMuted, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: t.surfaceWeak,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.border),
        ),
      ),
      onPressed: () => _showSheet(context),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _OptionTile({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE05454) : t.text;
    final bg = destructive
        ? const Color(0xFFE05454).withValues(alpha: 0.12)
        : t.surfaceWeak;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive ? color.withValues(alpha: 0.25) : t.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: destructive ? color.withValues(alpha: 0.12) : t.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: destructive ? color : t.goldText,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bingo banner tile ─────────────────────────────────────────────────────

class _FriendBingoBanner extends StatelessWidget {
  final BingoCard? card;
  final bool loading;
  final PintTheme t;
  final VoidCallback? onTap;

  const _FriendBingoBanner({
    required this.card,
    required this.loading,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final monthAbbr = card != null
        ? card!.monthLabel.split(' ').first.toUpperCase()
        : '';
    final linesText = card != null && card!.completedLines > 0
        ? ' · ${card!.completedLines} ${card!.completedLines == 1 ? 'Zeile' : 'Zeilen'}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.97, -0.26),
            end: const Alignment(0.97, 0.26),
            colors: [t.goldSoft, t.goldFaint],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.goldBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: t.border),
              ),
              child: SizedBox(
                width: 47,
                height: 47,
                child: card != null
                    ? GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                            ),
                        itemCount: 25,
                        itemBuilder: (_, i) => Opacity(
                          opacity: card!.cells[i].done ? 1.0 : 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              color: card!.cells[i].done
                                  ? t.gold
                                  : t.surfaceWeak,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                      )
                    : loading
                    ? const ShimmerBox()
                    : Icon(
                        Icons.grid_view_rounded,
                        size: 24,
                        color: t.textFaint,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🍺', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Bier-Bingo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (monthAbbr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: t.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            monthAbbr,
                            style: TextStyle(
                              color: t.goldInk,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.19,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (loading && card == null)
                    Text(
                      'Wird geladen...',
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (card != null)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.textMuted,
                        ),
                        children: [
                          TextSpan(
                            text: '${card!.totalDone}/25 erledigt',
                            style: TextStyle(
                              color: t.goldText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (linesText.isNotEmpty) TextSpan(text: linesText),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Karte nicht verfügbar',
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: onTap == null ? t.textFaint : t.goldText,
            ),
          ],
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

  static const _cols = 12;
  static const _rows = 7;
  static const _maxDiag = _cols - 1 + _rows - 1;
  static const _cellAnimMs = 280;
  static const _staggerMs = 22;
  static const _totalMs = _cellAnimMs + _staggerMs * _maxDiag;

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
                              : widget.t.streakCell[_drinkLevel(v)],
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
