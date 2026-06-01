import 'package:flutter/foundation.dart';
import '../models/feed_post.dart';
import '../services/post_service.dart';

class ProfilePostsProvider extends ChangeNotifier {
  final PostService _postService;

  ProfilePostsProvider(this._postService);

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

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _posts = await _postService.getMyPosts();
    } catch (_) {
      _posts = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void prepend(FeedPost post) {
    _posts = [post, ..._posts];
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await _postService.deletePost(postId);
    _posts = _posts.where((p) => p.id != postId).toList();
    notifyListeners();
  }
}
