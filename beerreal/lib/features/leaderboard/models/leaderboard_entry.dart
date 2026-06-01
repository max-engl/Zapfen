class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final int pints;
  final int cheersWk;
  final int pintMove;
  final int cheersMove;
  final bool isNew;
  final bool isYou;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.pints,
    required this.cheersWk,
    required this.pintMove,
    required this.cheersMove,
    required this.isNew,
    required this.isYou,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
      pints: (json['pints'] as num?)?.toInt() ?? 0,
      cheersWk: (json['cheersWk'] as num?)?.toInt() ?? 0,
      pintMove: (json['pintMove'] as num?)?.toInt() ?? 0,
      cheersMove: (json['cheersMove'] as num?)?.toInt() ?? 0,
      isNew: json['isNew'] as bool? ?? false,
      isYou: json['isYou'] as bool? ?? false,
    );
  }

  int valueFor(String metric) => metric == 'pints' ? pints : cheersWk;
  int moveFor(String metric) => metric == 'pints' ? pintMove : cheersMove;
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final int yourRank;
  final String yourPercentile;
  final int totalUsers;

  const LeaderboardData({
    required this.entries,
    required this.yourRank,
    required this.yourPercentile,
    required this.totalUsers,
  });
}
