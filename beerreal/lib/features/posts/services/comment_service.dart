import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/comment.dart';
import '../models/post_reaction.dart';

class CommentService {
  final ApiClient _client;

  CommentService(this._client);

  Future<List<Comment>> getComments(String postId) async {
    final response = await _client.dio.get(ApiConstants.postComments(postId));
    final list = response.data['comments'] as List<dynamic>;
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Comment> addComment(String postId, String text) async {
    final response = await _client.dio.post(
      ApiConstants.postComments(postId),
      data: {'text': text},
    );
    return Comment.fromJson(response.data['comment'] as Map<String, dynamic>);
  }

  Future<Comment> replyToComment(String commentId, String text) async {
    final response = await _client.dio.post(
      ApiConstants.replyToComment(commentId),
      data: {'text': text},
    );
    return Comment.fromJson(response.data['comment'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.dio.delete(ApiConstants.deleteComment(commentId));
  }

  Future<({String? myReaction, List<PostReaction> reactions})> reactToComment(
    String commentId,
    String emoji,
  ) async {
    final response = await _client.dio.post(
      ApiConstants.reactToComment(commentId),
      data: {'emoji': emoji},
    );
    final data = response.data as Map<String, dynamic>;
    final myReaction = data['myReaction'] as String?;
    final rawReactions = data['reactions'] as List<dynamic>? ?? [];
    return (
      myReaction: myReaction,
      reactions: rawReactions
          .map((e) => PostReaction.fromJson(e as Map<String, dynamic>, myReaction))
          .toList(),
    );
  }
}
