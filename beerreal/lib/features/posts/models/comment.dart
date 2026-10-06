import 'post_reaction.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final String text;
  final String? parentId;
  final DateTime createdAt;
  final String? myReaction;
  final List<PostReaction> reactions;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.text,
    this.parentId,
    required this.createdAt,
    this.myReaction,
    this.reactions = const [],
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final myReaction = json['myReaction'] as String?;
    final rawReactions = json['reactions'] as List<dynamic>? ?? [];
    final rawReplies = json['replies'] as List<dynamic>? ?? [];

    return Comment(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      postId: (json['postId'] ?? '') as String,
      userId: (user['_id'] ?? user['id'] ?? '') as String,
      username: (user['username'] ?? '') as String,
      avatarUrl: user['avatarUrl'] as String?,
      avatarColor: user['avatarColor'] as String?,
      avatarInitial: user['avatarInitial'] as String?,
      text: (json['text'] ?? '') as String,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      myReaction: myReaction,
      reactions: rawReactions
          .map(
            (e) => PostReaction.fromJson(e as Map<String, dynamic>, myReaction),
          )
          .toList(),
      replies: rawReplies
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Comment copyWith({
    String? myReaction,
    List<PostReaction>? reactions,
    List<Comment>? replies,
    bool clearMyReaction = false,
  }) => Comment(
    id: id,
    postId: postId,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    avatarColor: avatarColor,
    avatarInitial: avatarInitial,
    text: text,
    parentId: parentId,
    createdAt: createdAt,
    myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    reactions: reactions ?? this.reactions,
    replies: replies ?? this.replies,
  );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  int get totalReactions => reactions.fold(0, (sum, r) => sum + r.count);
}
