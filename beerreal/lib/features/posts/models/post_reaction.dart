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

const List<String> kReactionEmojis = ['🍺', '🔥', '😍', '💀'];
