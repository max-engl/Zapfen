import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/friends/models/api_friend.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/providers/feed_provider.dart';
import '../widgets/pint_loading.dart';
import '../widgets/post_card.dart';
import '../widgets/pint_refresh_logo.dart';
import '../widgets/shimmer_box.dart';
import 'friend_profile_screen.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';
import 'selfie_react_capture_screen.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onCapture;

  const FeedScreen({super.key, required this.onCapture});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  FeedProvider? _feedProvider;
  final _precachedIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feedProvider = context.read<FeedProvider>()..addListener(_onFeedUpdated);
      _feedProvider!.loadFeed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedProvider?.removeListener(_onFeedUpdated);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _feedProvider?.loadFeed();
    }
  }

  void _onFeedUpdated() {
    if (!mounted) return;
    _precacheIncoming(_feedProvider!.posts);
  }

  void _precacheIncoming(List<FeedPost> posts) {
    // Only precache a window of posts around the current scroll position to
    // prevent unbounded memory growth as the user scrolls through a long feed.
    const windowSize = 10;
    final currentIndex = _scrollController.hasClients
        ? (_scrollController.position.pixels / 600).floor()
        : 0;
    final lo = (currentIndex - 2).clamp(0, posts.length);
    final hi = (currentIndex + windowSize).clamp(0, posts.length);

    for (int i = lo; i < hi; i++) {
      final post = posts[i];
      if (!_precachedIds.add(post.id)) continue;
      if (post.imageUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            post.imageUrl,
            cacheKey: post.imagePath ?? post.id,
            cacheManager: AppCacheManager.instance,
          ),
          context,
          onError: (_, __) {},
        );
      }
      if (post.selfieUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            post.selfieUrl,
            cacheKey: post.selfiePath ?? '${post.id}_selfie',
            cacheManager: AppCacheManager.instance,
          ),
          context,
          onError: (_, __) {},
        );
      }
    }

    // Evict stale IDs so the set doesn't grow unboundedly across feed refreshes
    if (_precachedIds.length > 60) {
      _precachedIds.clear();
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<FeedProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final feed = context.watch<FeedProvider>();

    if (feed.loading && feed.posts.isEmpty) {
      return _ShimmerFeed(t: t);
    }

    if (feed.error != null && feed.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feed.error!,
                style: TextStyle(color: t.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => feed.loadFeed(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Text(
                    'Erneut versuchen',
                    style: TextStyle(
                      color: t.goldText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (feed.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: t.textMuted),
              const SizedBox(height: 12),
              Text(
                'Noch keine Beiträge.',
                style: TextStyle(
                  color: t.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Freunde hinzufügen, um ihre Biere hier zu sehen.',
                style: TextStyle(color: t.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: widget.onCapture,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Zuerst zapfen',
                    style: TextStyle(
                      color: t.goldInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().user?.id;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => feed.loadFeed(),
          builder: (_, state, pulledExtent, triggerDistance, __) =>
              PintRefreshLogo(
                state: state,
                pulledExtent: pulledExtent,
                triggerDistance: triggerDistance,
              ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Row(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'FREUNDE · HEUTE',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 1, color: t.border)),
                      const SizedBox(width: 8),
                      Text(
                        '${feed.posts.length}',
                        style: TextStyle(color: t.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final postIndex = index - 1;

              if (postIndex == feed.posts.length) {
                if (feed.loadingMore) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: PintDots(color: t.gold, dotSize: 6, spacing: 5),
                    ),
                  );
                }
                if (feed.loadMoreFailed) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: GestureDetector(
                      onTap: () => feed.retryLoadMore(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: t.surfaceWeak,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border),
                        ),
                        child: Center(
                          child: Text(
                            'Laden fehlgeschlagen – tippe zum Wiederholen',
                            style: TextStyle(
                              color: t.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final p = feed.posts[postIndex];
              return PostCard(
                key: ValueKey(p.id),
                post: p,
                enableHero: false,
                onReact: (emoji) => feed.toggleReaction(p.id, emoji),
                onSelfieReact: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SelfieReactCaptureScreen(
                      onSend: (bytes, emoji) => feed.sendSelfieReaction(
                        p.id,
                        imageBytes: bytes,
                        filename: 'selfie_reaction.jpg',
                        emoji: emoji,
                      ),
                    ),
                  ),
                ),
                onRemoveSelfieReaction: (reactionId) =>
                    feed.removeSelfieReaction(p.id, reactionId),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)),
                ),
                onDelete: p.userId == currentUserId
                    ? () => feed.deletePost(p.id)
                    : null,
                onProfileTap: p.userId == currentUserId
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfileScreen(standaloneRoute: true),
                        ),
                      )
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FriendProfileScreen(
                            friend: ApiFriend(
                              id: p.userId,
                              username: p.username,
                              avatarUrl: p.avatarUrl,
                              avatarColor: p.avatarColor,
                              avatarInitial: p.avatarInitial,
                            ),
                          ),
                        ),
                      ),
              );
            }, childCount: feed.posts.length + 2),
          ),
        ),
      ],
    );
  }
}

class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed({required this.t});
  final PintTheme t;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: ShimmerBox.circle(),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 13,
                      child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      height: 11,
                      child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ShimmerBox(borderRadius: BorderRadius.circular(22)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              height: 13,
              child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }
}
