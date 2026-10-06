class PostMention {
  final String userId;
  final String username;
  final String? avatarUrl;

  const PostMention({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  factory PostMention.fromJson(Map<String, dynamic> json) => PostMention(
        userId: (json['userId'] ?? json['id'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        avatarUrl: json['avatarUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
      };
}
