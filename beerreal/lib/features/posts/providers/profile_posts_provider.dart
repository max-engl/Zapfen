import 'package:flutter/foundation.dart';
import '../models/feed_post.dart';
import '../services/post_service.dart';
import '../../../core/feed_database.dart';

class ProfilePostsProvider extends ChangeNotifier {
  final PostService _postService;
  final FeedDatabase _db;

  ProfilePostsProvider(this._postService, this._db);

  List<FeedPost> _posts = [];
  bool _loading = false;

  List<FeedPost> get posts => _posts;
  bool get loading => _loading;

  List<int> get heatmapGrid => buildHeatmapFromPosts(_posts);

  int get totalPints => _posts.length;

  int get streak {
    if (_posts.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _posts
        .map((p) => DateTime(p.createdAt.year, p.createdAt.month, p.createdAt.day))
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

  int get spots {
    return _posts
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => '${(p.lat! * 100).round()},${(p.lng! * 100).round()}')
        .toSet()
        .length;
  }

  /// Reads the SQLite cache into [_posts] without a network call.
  /// Call at app startup so the profile renders instantly on first open.
  Future<void> preloadFromCache() async {
    final cached = await _db.loadProfilePosts();
    if (cached.isNotEmpty) {
      _posts = cached;
      notifyListeners();
    }
  }

  Future<void> load() async {
    // Only show shimmer when there's no cached data to display.
    if (_posts.isEmpty) {
      _loading = true;
      notifyListeners();
    }

    bool dirty = false;
    try {
      final fresh = await _postService.getMyPosts();
      final freshIds = fresh.map((p) => p.id).join(',');
      final currentIds = _posts.map((p) => p.id).join(',');
      if (freshIds != currentIds) {
        _posts = fresh;
        dirty = true;
        _db.saveProfilePosts(fresh);
      }
    } catch (_) {}

    if (_loading || dirty) {
      _loading = false;
      notifyListeners();
    }
  }

  void prepend(FeedPost post) {
    _posts = [post, ..._posts];
    notifyListeners();
    _db.saveProfilePosts(_posts);
  }

  Future<void> deletePost(String postId) async {
    await _postService.deletePost(postId);
    _posts = _posts.where((p) => p.id != postId).toList();
    notifyListeners();
    _db.saveProfilePosts(_posts);
  }
}
