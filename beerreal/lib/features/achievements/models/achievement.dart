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
