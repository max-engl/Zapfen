class Achievement {
  final String id;
  final String icon;
  final String name;
  final String blurb;
  final bool earned;
  final int have;
  final int goal;
  final String statusLabel;
  final DateTime? earnedDate;
  final bool hidden;

  const Achievement({
    required this.id,
    required this.icon,
    required this.name,
    required this.blurb,
    required this.earned,
    required this.have,
    required this.goal,
    required this.statusLabel,
    this.earnedDate,
    this.hidden = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'icon': icon,
        'name': name,
        'blurb': blurb,
        'earned': earned,
        'have': have,
        'goal': goal,
        'statusLabel': statusLabel,
        'earnedDate': earnedDate?.toIso8601String(),
        'hidden': hidden,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final earnedDateValue = json['earnedDate'] as String?;
    return Achievement(
      id: (json['id'] ?? '') as String,
      icon: (json['icon'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      blurb: (json['blurb'] ?? '') as String,
      earned: (json['earned'] ?? false) as bool,
      have: (json['have'] as num?)?.toInt() ?? 0,
      goal: (json['goal'] as num?)?.toInt() ?? 1,
      statusLabel: (json['statusLabel'] ?? '') as String,
      earnedDate: earnedDateValue == null
          ? null
          : DateTime.tryParse(earnedDateValue),
      hidden: (json['hidden'] ?? false) as bool,
    );
  }
}

class FriendAchievementStanding {
  final String userId;
  final String username;
  final String avatarColor;
  final String avatarInitial;
  final String? avatarUrl;
  final bool isSelf;
  final bool earned;
  final DateTime? earnedDate;
  final int have;
  final int goal;

  const FriendAchievementStanding({
    required this.userId,
    required this.username,
    required this.avatarColor,
    required this.avatarInitial,
    this.avatarUrl,
    required this.isSelf,
    required this.earned,
    this.earnedDate,
    required this.have,
    required this.goal,
  });

  factory FriendAchievementStanding.fromJson(Map<String, dynamic> j) {
    final earnedDateRaw = j['earnedDate'] as String?;
    return FriendAchievementStanding(
      userId: (j['userId'] ?? '') as String,
      username: (j['username'] ?? '') as String,
      avatarColor: (j['avatarColor'] ?? '#F6B733') as String,
      avatarInitial: (j['avatarInitial'] ?? '?') as String,
      avatarUrl: j['avatarUrl'] as String?,
      isSelf: (j['isSelf'] ?? false) as bool,
      earned: (j['earned'] ?? false) as bool,
      earnedDate: earnedDateRaw == null ? null : DateTime.tryParse(earnedDateRaw),
      have: (j['have'] as num?)?.toInt() ?? 0,
      goal: (j['goal'] as num?)?.toInt() ?? 1,
    );
  }
}

class AchievementLocationTarget {
  final String id;
  final String icon;
  final String name;
  final String blurb;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool earned;
  final int have;
  final int goal;
  final String statusLabel;

  const AchievementLocationTarget({
    required this.id,
    required this.icon,
    required this.name,
    required this.blurb,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.earned,
    required this.have,
    required this.goal,
    required this.statusLabel,
  });

  factory AchievementLocationTarget.fromJson(Map<String, dynamic> json) {
    return AchievementLocationTarget(
      id: (json['id'] ?? '') as String,
      icon: (json['icon'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      blurb: (json['blurb'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 0,
      earned: (json['earned'] ?? false) as bool,
      have: (json['have'] as num?)?.toInt() ?? 0,
      goal: (json['goal'] as num?)?.toInt() ?? 1,
      statusLabel: (json['statusLabel'] ?? '') as String,
    );
  }
}
