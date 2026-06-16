class SelfieReaction {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final String imageUrl;
  final DateTime createdAt;

  const SelfieReaction({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.imageUrl,
    required this.createdAt,
  });

  factory SelfieReaction.fromJson(Map<String, dynamic> json) => SelfieReaction(
    id: (json['id'] ?? '').toString(),
    userId: (json['userId'] ?? '').toString(),
    username: (json['username'] ?? '') as String,
    avatarUrl: json['avatarUrl'] as String?,
    avatarColor: json['avatarColor'] as String?,
    avatarInitial: json['avatarInitial'] as String?,
    imageUrl: (json['imageUrl'] ?? '') as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'avatarUrl': avatarUrl,
    'avatarColor': avatarColor,
    'avatarInitial': avatarInitial,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
  };
}
