import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../models/post_reaction.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _service;
  final String postId;

  CommentProvider(this._service, {required this.postId});

  List<Comment> _comments = [];
  bool _loading = false;
  String? _error;
  String? _replyingToId;
  String? _replyingToUsername;

  List<Comment> get comments => _comments;
  bool get loading => _loading;
  String? get error => _error;
  String? get replyingToId => _replyingToId;
  String? get replyingToUsername => _replyingToUsername;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _comments = await _service.getComments(postId);
    } catch (e) {
      _error = 'Could not load comments.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addComment(String text) async {
    try {
      final comment = await _service.addComment(postId, text);
      _comments = [..._comments, comment];
      notifyListeners();
    } catch (e) {
      debugPrint('addComment error: $e');
      rethrow;
    }
  }

  Future<void> addReply(String text) async {
    if (_replyingToId == null) return;
    try {
      final reply = await _service.replyToComment(_replyingToId!, text);
      _comments = _comments.map((c) {
        if (c.id == _replyingToId) {
          return c.copyWith(replies: [...c.replies, reply]);
        }
        return c;
      }).toList();
      _replyingToId = null;
      _replyingToUsername = null;
      notifyListeners();
    } catch (e) {
      debugPrint('addReply error: $e');
      rethrow;
    }
  }

  void startReply(String commentId, String username) {
    _replyingToId = commentId;
    _replyingToUsername = username;
    notifyListeners();
  }

  void cancelReply() {
    _replyingToId = null;
    _replyingToUsername = null;
    notifyListeners();
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _service.deleteComment(commentId);
      _comments = _comments
          .where((c) => c.id != commentId)
          .map((c) => c.copyWith(
                replies: c.replies.where((r) => r.id != commentId).toList(),
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('deleteComment error: $e');
    }
  }

  Future<void> reactToComment(String commentId, String emoji) async {
    try {
      final result = await _service.reactToComment(commentId, emoji);
      _comments = _applyCommentReaction(_comments, commentId, result.myReaction, result.reactions);
      notifyListeners();
    } catch (e) {
      debugPrint('reactToComment error: $e');
    }
  }

  List<Comment> _applyCommentReaction(
    List<Comment> comments,
    String commentId,
    String? myReaction,
    List<PostReaction> reactions,
  ) {
    return comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(
          myReaction: myReaction,
          reactions: reactions,
          clearMyReaction: myReaction == null,
        );
      }
      final updatedReplies = c.replies.map((r) {
        if (r.id == commentId) {
          return r.copyWith(
            myReaction: myReaction,
            reactions: reactions,
            clearMyReaction: myReaction == null,
          );
        }
        return r;
      }).toList();
      return c.copyWith(replies: updatedReplies);
    }).toList();
  }

  int get totalCount {
    int count = _comments.length;
    for (final c in _comments) {
      count += c.replies.length;
    }
    return count;
  }
}
