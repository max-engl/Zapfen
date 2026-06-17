import 'package:flutter/foundation.dart';
import '../models/feed_post.dart';
import '../services/post_service.dart';
import '../../../core/feed_database.dart';
import '../../../core/geocoding_service.dart';

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

  int get postsToday {
    final now = DateTime.now();
    return _posts.where((p) {
      final d = p.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  /// Posts within the last 24 hours, each as a fractional local hour-of-day
  /// (0–24) — feeds the "Last 24h" widget's timeline track.
  List<double> get last24hHours {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _posts
        .where((p) => p.createdAt.isAfter(cutoff))
        .map((p) => p.createdAt.hour + p.createdAt.minute / 60.0)
        .toList();
  }

  /// Last 3 weeks of activity bucketed into 4 intensity levels (0–3) for the
  /// "Streak" widget's mini grid. Last entry is today.
  List<int> get widgetStreakGrid {
    final grid = heatmapGrid; // 84 days, oldest..today
    final last21 = grid.sublist(grid.length - 21);
    return last21.map((count) {
      if (count <= 0) return 0;
      if (count == 1) return 1;
      if (count <= 3) return 2;
      return 3;
    }).toList();
  }

  List<String> get countries {
    final set = <String>{};
    for (final p in _posts) {
      if (p.country != null && p.country!.isNotEmpty) set.add(p.country!);
    }
    return set.toList()..sort();
  }

  Future<void> _geocodeMissingCountries() async {
    final missing = _posts
        .where(
          (p) =>
              (p.country == null || p.country!.isEmpty) &&
              p.lat != null &&
              p.lng != null,
        )
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
    if (changed) {
      _posts = updated;
      notifyListeners();
      _db.saveProfilePosts(_posts);
    }
  }

  /// Reads the SQLite cache into [_posts] without a network call.
  /// Call at app startup so the profile renders instantly on first open.
  Future<void> preloadFromCache() async {
    final cached = await _db.loadProfilePosts();
    if (cached.isNotEmpty) {
      _posts = cached;
      notifyListeners();
    }
    _geocodeMissingCountries();
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
    _geocodeMissingCountries();
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

  void applyUpdate(FeedPost updated) {
    final idx = _posts.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    _posts = List.of(_posts)..[idx] = updated;
    notifyListeners();
    _db.saveProfilePosts(_posts);
  }
}
