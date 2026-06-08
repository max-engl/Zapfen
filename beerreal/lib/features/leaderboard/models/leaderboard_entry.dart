class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final int pints;
  final int drinksWk;
  final int drinksMo;
  final int pintMove;
  final int wkMove;
  final int moMove;
  final bool isNew;
  final bool isYou;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.pints,
    required this.drinksWk,
    required this.drinksMo,
    required this.pintMove,
    required this.wkMove,
    required this.moMove,
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
      drinksWk: (json['drinksWk'] as num?)?.toInt() ?? 0,
      drinksMo: (json['drinksMo'] as num?)?.toInt() ?? 0,
      pintMove: (json['pintMove'] as num?)?.toInt() ?? 0,
      wkMove: (json['wkMove'] as num?)?.toInt() ?? 0,
      moMove: (json['moMove'] as num?)?.toInt() ?? 0,
      isNew: json['isNew'] as bool? ?? false,
      isYou: json['isYou'] as bool? ?? false,
    );
  }

  int valueFor(String metric) {
    if (metric == 'drinksWk') return drinksWk;
    if (metric == 'drinksMo') return drinksMo;
    return pints;
  }

  int moveFor(String metric) {
    if (metric == 'drinksWk') return wkMove;
    if (metric == 'drinksMo') return moMove;
    return pintMove;
  }
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
