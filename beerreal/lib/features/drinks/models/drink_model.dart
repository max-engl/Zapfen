class DrinkModel {
  final String id;
  final String name;
  final String emoji;
  final bool isDefault;
  final bool isCustom;

  const DrinkModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isDefault,
    required this.isCustom,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'isDefault': isDefault,
        'isCustom': isCustom,
      };

  factory DrinkModel.fromJson(Map<String, dynamic> j, {bool isCustom = false}) {
    return DrinkModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '🍺',
      isDefault: j['isDefault'] as bool? ?? false,
      isCustom: isCustom,
    );
  }
}
