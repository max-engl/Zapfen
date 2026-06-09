import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/feed_post.dart';
import '../models/post_reaction.dart';

class PostService {
  final ApiClient _client;

  PostService(this._client);

  Future<({List<FeedPost> posts, bool hasMore})> getFeed({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.dio.get(
      ApiConstants.feed,
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = response.data['posts'] as List<dynamic>;
    final hasMore = response.data['hasMore'] as bool? ?? false;
    return (
      posts: list
          .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: hasMore,
    );
  }

  Future<List<FeedPost>> getMyPosts() async {
    final response = await _client.dio.get(ApiConstants.myPosts);
    final list = response.data['posts'] as List<dynamic>;
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedPost> getPostById(String postId) async {
    final response = await _client.dio.get(ApiConstants.postById(postId));
    return FeedPost.fromJson(response.data['post'] as Map<String, dynamic>);
  }

  Future<List<FeedPost>> getUserPosts(String userId) async {
    final response = await _client.dio.get(ApiConstants.userPosts(userId));
    final list = response.data['posts'] as List<dynamic>;
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedPost> uploadPost({
    required List<int> imageBytes,
    required String filename,
    required List<int> selfieBytes,
    required String selfieFilename,
    required String caption,
    double? lat,
    double? lng,
    String? country,
    String? drinkName,
    String? drinkEmoji,
    int? rating,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      'selfie': MultipartFile.fromBytes(selfieBytes, filename: selfieFilename),
      'caption': caption,
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (country != null && country.isNotEmpty) 'country': country,
      if (drinkName != null && drinkName.isNotEmpty) 'drinkName': drinkName,
      if (drinkEmoji != null && drinkEmoji.isNotEmpty) 'drinkEmoji': drinkEmoji,
      if (rating != null) 'rating': rating.toString(),
    });
    final response = await _client.dio.post(
      ApiConstants.uploadPost,
      data: formData,
    );
    return FeedPost.fromJson(response.data['post'] as Map<String, dynamic>);
  }

  Future<List<FeedPost>> getMapPosts() async {
    final response = await _client.dio.get(ApiConstants.mapPosts);
    final list = response.data['posts'] as List<dynamic>;
    return list
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({bool liked, int likes})> toggleLike(String postId) async {
    final response = await _client.dio.post(ApiConstants.likePost(postId));
    final data = response.data as Map<String, dynamic>;
    return (liked: data['liked'] as bool, likes: data['likes'] as int);
  }

  Future<int> recordView(String postId) async {
    final response = await _client.dio.post(ApiConstants.viewPost(postId));
    return (response.data['views'] as num?)?.toInt() ?? 0;
  }

  Future<void> deletePost(String postId) async {
    await _client.dio.delete(ApiConstants.deletePost(postId));
  }

  Future<List<ReactionActor>> getPostReactions(String postId) async {
    final response = await _client.dio.get(ApiConstants.reactToPost(postId));
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ReactionActor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<
    ({String? myReaction, List<PostReaction> reactions, int totalReactions})
  >
  toggleReaction(String postId, String emoji) async {
    final response = await _client.dio.post(
      ApiConstants.reactToPost(postId),
      data: {'emoji': emoji},
    );
    final data = response.data as Map<String, dynamic>;
    final myReaction = data['myReaction'] as String?;
    final rawReactions = data['reactions'] as List<dynamic>? ?? [];
    return (
      myReaction: myReaction,
      reactions: rawReactions
          .map(
            (e) => PostReaction.fromJson(e as Map<String, dynamic>, myReaction),
          )
          .toList(),
      totalReactions: (data['totalReactions'] as num?)?.toInt() ?? 0,
    );
  }
}
