class PostReaction {
  final String emoji;
  final int count;
  final bool reactedByMe;

  const PostReaction({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
  });

  factory PostReaction.fromJson(Map<String, dynamic> json, String? myReaction) {
    final emoji = json['emoji'] as String;
    return PostReaction(
      emoji: emoji,
      count: (json['count'] as num).toInt(),
      reactedByMe: emoji == myReaction,
    );
  }

  PostReaction copyWith({int? count, bool? reactedByMe}) => PostReaction(
    emoji: emoji,
    count: count ?? this.count,
    reactedByMe: reactedByMe ?? this.reactedByMe,
  );
}

const List<String> kReactionEmojis = ['⭐', '🔥', '😍', '💀', '😂'];

class ReactionActor {
  final String emoji;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;

  const ReactionActor({
    required this.emoji,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
  });

  factory ReactionActor.fromJson(Map<String, dynamic> json) => ReactionActor(
    emoji: json['emoji'] as String,
    userId: json['userId'] as String,
    username: json['username'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    avatarColor: json['avatarColor'] as String?,
    avatarInitial: json['avatarInitial'] as String?,
  );
}
