/// One small avatar shown in the "Friends today" widget's avatar stack.
class WidgetAvatar {
  final String initial;
  final String colorHex;

  const WidgetAvatar({required this.initial, required this.colorHex});

  Map<String, dynamic> toMap() => {'initial': initial, 'colorHex': colorHex};
}

/// One bar of the "Circle rank" widget's mini podium.
class WidgetPodiumEntry {
  final int rank;
  final int value;
  final bool isYou;

  const WidgetPodiumEntry({
    required this.rank,
    required this.value,
    required this.isYou,
  });

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'value': value,
    'isYou': isYou,
  };
}

/// Everything the five iOS home-screen widgets need to render, gathered from
/// whichever app providers currently have data. Pushed to the native side as
/// a single JSON-ish payload over the `beerreal/widget` method channel.
class WidgetSnapshot {
  final int totalPints;
  final int pintsToday;

  final int last24hCount;
  final List<double> last24hHours;

  final int streakDays;
  final List<int> streakGrid;

  final int friendsTodayCount;
  final int friendsTotal;
  final List<WidgetAvatar> friendAvatars;

  final int circleRank;
  final int circleTotal;
  final int circleTrend;
  final List<WidgetPodiumEntry> circlePodium;

  const WidgetSnapshot({
    required this.totalPints,
    required this.pintsToday,
    required this.last24hCount,
    required this.last24hHours,
    required this.streakDays,
    required this.streakGrid,
    required this.friendsTodayCount,
    required this.friendsTotal,
    required this.friendAvatars,
    required this.circleRank,
    required this.circleTotal,
    required this.circleTrend,
    required this.circlePodium,
  });

  Map<String, dynamic> toMap() => {
    'totalPints': totalPints,
    'pintsToday': pintsToday,
    'last24hCount': last24hCount,
    // Cap the payload — the widget only ever plots a handful of bars.
    'last24hHours': last24hHours.take(12).toList(),
    'streakDays': streakDays,
    'streakGrid': streakGrid,
    'friendsTodayCount': friendsTodayCount,
    'friendsTotal': friendsTotal,
    'friendAvatars': friendAvatars.map((a) => a.toMap()).toList(),
    'circleRank': circleRank,
    'circleTotal': circleTotal,
    'circleTrend': circleTrend,
    'circlePodium': circlePodium.map((p) => p.toMap()).toList(),
    'updatedAt': DateTime.now().millisecondsSinceEpoch / 1000.0,
  };
}
