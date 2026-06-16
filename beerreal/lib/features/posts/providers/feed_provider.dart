import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/feed_post.dart';
import '../models/selfie_reaction.dart';
import '../services/post_service.dart';
import '../../../core/app_cache_manager.dart';
import '../../../core/feed_database.dart';

class FeedProvider extends ChangeNotifier {
  final PostService _postService;
  final FeedDatabase _feedDb;

  FeedProvider(this._postService, this._feedDb);

  List<FeedPost> _posts = [];
  // Start as loading so the first frame shows shimmer, never the empty-state.
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _loadMoreFailed = false;
  bool _isOffline = false;
  int _page = 0;
  String? _error;

  static const _pageSize = 10;

  List<FeedPost> get posts => _posts;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get loadMoreFailed => _loadMoreFailed;
  bool get isOffline => _isOffline;
  String? get error => _error;
  bool isLiked(String postId) =>
      _posts.any((p) => p.id == postId && p.likedByMe);

  /// Reads the SQLite cache into [_posts] and returns immediately.
  /// Called during the app loading screen so the feed is populated before
  /// the UI is shown. Does not fire a network request.
  Future<void> preloadFromCache() async {
    final cached = await _feedDb.loadPosts();
    if (cached.isNotEmpty) {
      _posts = cached;
      // Do NOT prefetch here — cached URLs are signed and expire after 1 hour.
      // CachedNetworkImage will serve from disk cache if available, or show
      // a placeholder until fresh URLs arrive from the network.
      _loading = false; // data ready — hide loading state
    }
    // If cache is empty, keep _loading=true so the feed shows shimmer
    // rather than the empty-state the moment PintApp first renders.
    notifyListeners();
  }

  /// Refreshes the feed from the network.
  /// If posts are already loaded (e.g. from [preloadFromCache]), the existing
  /// content stays visible — no shimmer — and updates silently when done.
  Future<void> loadFeed() async {
    _error = null;
    _page = 0;
    _hasMore = true;
    _loadMoreFailed = false;

    if (_posts.isEmpty && !_loading) {
      // Only show shimmer if we're not already in a loading state
      // (preloadFromCache keeps _loading=true when cache is empty).
      _loading = true;
      notifyListeners();
    }

    if (_posts.isEmpty) {
      final cached = await _feedDb.loadPosts();
      if (cached.isNotEmpty) {
        _posts = cached;
        notifyListeners();
        // Do not prefetch cached posts — signed URLs may be expired.
      }
    }

    try {
      final result = await _postService.getFeed(page: 1, limit: _pageSize);
      final freshIds = result.posts.map((p) => p.id).join(',');
      final currentIds = _posts.map((p) => p.id).join(',');
      final idsChanged = freshIds != currentIds;

      // Always replace posts so reactions/likes are never stale from the cache.
      _posts = result.posts;
      _hasMore = result.hasMore;
      _page = 1;
      _isOffline = false;
      _feedDb.savePosts(_posts);
      if (idsChanged) _prefetchImages(_posts);
    } on DioException catch (e) {
      _error = _extractError(e);
      _isOffline = e.response == null; // no response = network unreachable
    } catch (e) {
      _error = 'Could not load feed.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void retryLoadMore() {
    _loadMoreFailed = false;
    notifyListeners();
    loadMore();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _loadMoreFailed) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _postService.getFeed(
        page: _page + 1,
        limit: _pageSize,
      );
      _posts = [..._posts, ...result.posts];
      _hasMore = result.hasMore;
      _page += 1;

      _feedDb.savePosts(_posts);
      _prefetchImages(result.posts);
    } on DioException catch (e) {
      _loadMoreFailed = true;
      debugPrint('loadMore error: ${_extractError(e)}');
    } catch (e) {
      _loadMoreFailed = true;
      debugPrint('loadMore error: $e');
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void prepend(FeedPost post) {
    _posts = [post, ..._posts];
    notifyListeners();
    _feedDb.savePosts(_posts);
  }

  Future<void> deletePost(String postId) async {
    await _postService.deletePost(postId);
    _posts = _posts.where((p) => p.id != postId).toList();
    notifyListeners();
    _feedDb.savePosts(_posts);
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final original = _posts[idx];
    final optimisticLiked = !original.likedByMe;
    final optimisticLikes = original.likes + (optimisticLiked ? 1 : -1);
    _posts = List.of(_posts)
      ..[idx] = original.copyWith(
        likedByMe: optimisticLiked,
        likes: optimisticLikes,
      );
    notifyListeners();

    try {
      final result = await _postService.toggleLike(postId);
      _posts = List.of(_posts)
        ..[idx] = _posts[idx].copyWith(
          likedByMe: result.liked,
          likes: result.likes,
        );
      notifyListeners();
    } catch (_) {
      _posts = List.of(_posts)..[idx] = original;
      notifyListeners();
    }
  }

  Future<void> toggleReaction(String postId, String emoji) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final original = _posts[idx];
    final isRemoving = original.myReaction == emoji;
    final optimisticTotal =
        original.totalReactions +
        (isRemoving ? -1 : (original.myReaction == null ? 1 : 0));
    _posts = List.of(_posts)
      ..[idx] = original.copyWith(
        myReaction: isRemoving ? null : emoji,
        clearMyReaction: isRemoving,
        totalReactions: optimisticTotal,
      );
    notifyListeners();

    try {
      final result = await _postService.toggleReaction(postId, emoji);
      _posts = List.of(_posts)
        ..[idx] = _posts[idx].copyWith(
          myReaction: result.myReaction,
          clearMyReaction: result.myReaction == null,
          reactions: result.reactions,
          totalReactions: result.totalReactions,
        );
      notifyListeners();
    } catch (_) {
      _posts = List.of(_posts)..[idx] = original;
      notifyListeners();
    }
  }

  Future<SelfieReaction> sendSelfieReaction(
    String postId, {
    required List<int> imageBytes,
    required String filename,
    String? emoji,
  }) async {
    final reaction = await _postService.sendSelfieReaction(
      postId,
      imageBytes: imageBytes,
      filename: filename,
      emoji: emoji,
    );
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _posts[idx];
      final withoutMine = post.selfieReactions
          .where((r) => r.userId != reaction.userId)
          .toList();
      _posts = List.of(_posts)
        ..[idx] = post.copyWith(selfieReactions: [...withoutMine, reaction]);
      notifyListeners();
      _feedDb.savePosts(_posts);
    }
    return reaction;
  }

  Future<void> removeSelfieReaction(String postId, String reactionId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) {
      await _postService.removeSelfieReaction(postId);
      return;
    }

    final original = _posts[idx];
    final optimistic = original.selfieReactions
        .where((r) => r.id != reactionId)
        .toList();
    _posts = List.of(_posts)
      ..[idx] = original.copyWith(selfieReactions: optimistic);
    notifyListeners();

    try {
      await _postService.removeSelfieReaction(postId);
      _feedDb.savePosts(_posts);
    } catch (_) {
      _posts = List.of(_posts)..[idx] = original;
      notifyListeners();
    }
  }

  void updateCommentCount(String postId, int delta) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    _posts = List.of(_posts)
      ..[idx] = post.copyWith(comments: post.comments + delta);
    notifyListeners();
  }

  void _prefetchImages(List<FeedPost> posts) {
    for (final post in posts) {
      if (post.imageUrl.isNotEmpty) {
        AppCacheManager.instance
            .downloadFile(post.imageUrl, key: post.imagePath ?? post.id)
            .then<void>((_) {}, onError: (_) {});
      }
      if (post.selfieUrl.isNotEmpty) {
        AppCacheManager.instance
            .downloadFile(
              post.selfieUrl,
              key: post.selfiePath ?? '${post.id}_selfie',
            )
            .then<void>((_) {}, onError: (_) {});
      }
      for (final reaction in post.selfieReactions) {
        if (reaction.imageUrl.isNotEmpty) {
          AppCacheManager.instance
              .downloadFile(reaction.imageUrl, key: reaction.cacheKey)
              .then<void>((_) {}, onError: (_) {});
        }
      }
      final avatar = post.avatarUrl;
      if (avatar != null && avatar.isNotEmpty) {
        AppCacheManager.instance
            .downloadFile(avatar)
            .then<void>((_) {}, onError: (_) {});
      }
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message'] as String? ?? 'Request failed.';
    return 'Request failed.';
  }
}
