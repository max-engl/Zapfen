class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String recommendedVersion;
  final String mandatoryVersion;
  final bool updateRecommended;
  final bool updateRequired;
  final List<String> patchNotes;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.recommendedVersion,
    required this.mandatoryVersion,
    required this.updateRecommended,
    required this.updateRequired,
    required this.patchNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    currentVersion: (json['currentVersion'] ?? '').toString(),
    latestVersion: (json['latestVersion'] ?? '').toString(),
    recommendedVersion: (json['recommendedVersion'] ?? '').toString(),
    mandatoryVersion: (json['mandatoryVersion'] ?? '').toString(),
    updateRecommended: json['updateRecommended'] as bool? ?? false,
    updateRequired: json['updateRequired'] as bool? ?? false,
    patchNotes: _parsePatchNotes(json['patchNotes']),
  );

  static const none = AppUpdateInfo(
    currentVersion: '',
    latestVersion: '',
    recommendedVersion: '',
    mandatoryVersion: '',
    updateRecommended: false,
    updateRequired: false,
    patchNotes: [],
  );

  static List<String> _parsePatchNotes(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }
}
