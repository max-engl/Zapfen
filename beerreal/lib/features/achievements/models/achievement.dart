class Achievement {
  final String id;
  final String icon;
  final String name;
  final String blurb;
  final bool earned;
  final int have;
  final int goal;
  final DateTime? earnedDate;

  const Achievement({
    required this.id,
    required this.icon,
    required this.name,
    required this.blurb,
    required this.earned,
    required this.have,
    required this.goal,
    this.earnedDate,
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
      earnedDate: earnedDateValue == null
          ? null
          : DateTime.tryParse(earnedDateValue),
    );
  }
}
