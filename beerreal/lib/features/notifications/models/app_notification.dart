class AppNotification {
  final String id;
  final String type; // poured | cheers | comment | request | accepted
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? actorAvatarColor;
  final String? actorAvatarInitial;
  final String? postId;
  final String? postThumbUrl;
  final int mutualCount;
  bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.actorId,
    this.actorUsername,
    this.actorAvatarUrl,
    this.actorAvatarColor,
    this.actorAvatarInitial,
    this.postId,
    this.postThumbUrl,
    this.mutualCount = 0,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:             json['id'] as String,
      type:           json['type'] as String,
      actorId:        json['actorId'] as String?,
      actorUsername:  json['actorUsername'] as String?,
      actorAvatarUrl:     json['actorAvatarUrl'] as String?,
      actorAvatarColor:   json['actorAvatarColor'] as String?,
      actorAvatarInitial: json['actorAvatarInitial'] as String?,
      postId:             json['postId'] as String?,
      postThumbUrl:   json['postThumbUrl'] as String?,
      mutualCount:    (json['mutualCount'] as num?)?.toInt() ?? 0,
      read:           json['read'] as bool? ?? false,
      createdAt:      DateTime.parse(json['createdAt'] as String),
    );
  }

  // "Heute" / "Diese Woche" / "Früher"
  String get group {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (!day.isBefore(today)) return 'Heute';
    if (!day.isBefore(weekAgo)) return 'Diese Woche';
    return 'Früher';
  }

  // "2m" / "3h" / "Mo" / "12. Mai"
  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) {
      const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      return days[createdAt.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${createdAt.day}. ${months[createdAt.month - 1]}';
  }
}
