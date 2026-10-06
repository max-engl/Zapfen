class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final int reviews;
  final int reviewsWk;
  final int reviewsMo;
  final int reviewMove;
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
    required this.reviews,
    required this.reviewsWk,
    required this.reviewsMo,
    required this.reviewMove,
    required this.wkMove,
    required this.moMove,
    required this.isNew,
    required this.isYou,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'avatarColor': avatarColor,
        'avatarInitial': avatarInitial,
        'reviews': reviews,
        'reviewsWk': reviewsWk,
        'reviewsMo': reviewsMo,
        'reviewMove': reviewMove,
        'wkMove': wkMove,
        'moMove': moMove,
        'isNew': isNew,
        'isYou': isYou,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      reviewsWk: (json['reviewsWk'] as num?)?.toInt() ?? 0,
      reviewsMo: (json['reviewsMo'] as num?)?.toInt() ?? 0,
      reviewMove: (json['reviewMove'] as num?)?.toInt() ?? 0,
      wkMove: (json['wkMove'] as num?)?.toInt() ?? 0,
      moMove: (json['moMove'] as num?)?.toInt() ?? 0,
      isNew: json['isNew'] as bool? ?? false,
      isYou: json['isYou'] as bool? ?? false,
    );
  }

  int valueFor(String metric) {
    if (metric == 'reviewsWk') return reviewsWk;
    if (metric == 'reviewsMo') return reviewsMo;
    return reviews;
  }

  int moveFor(String metric) {
    if (metric == 'reviewsWk') return wkMove;
    if (metric == 'reviewsMo') return moMove;
    return reviewMove;
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
