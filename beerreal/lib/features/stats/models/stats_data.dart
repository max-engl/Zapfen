class StatsTimelinePoint {
  final String label;
  final int count;
  const StatsTimelinePoint({required this.label, required this.count});

  Map<String, dynamic> toJson() => {'label': label, 'count': count};

  factory StatsTimelinePoint.fromJson(Map<String, dynamic> json) =>
      StatsTimelinePoint(
        label: json['label'] as String,
        count: (json['count'] as num).toInt(),
      );
}

class StatsStyleEntry {
  final String name;
  final int pct;
  const StatsStyleEntry({required this.name, required this.pct});

  Map<String, dynamic> toJson() => {'name': name, 'pct': pct};

  factory StatsStyleEntry.fromJson(Map<String, dynamic> json) => StatsStyleEntry(
        name: json['name'] as String,
        pct: (json['pct'] as num).toInt(),
      );
}

class StatsData {
  final int total;
  final int deltaPct;
  final List<StatsTimelinePoint> timeline;
  final List<int> dow;
  final String peakHour;
  final double avgPerHead;
  final List<StatsStyleEntry> styles;
  final int userCount;

  const StatsData({
    required this.total,
    required this.deltaPct,
    required this.timeline,
    required this.dow,
    required this.peakHour,
    required this.avgPerHead,
    required this.styles,
    required this.userCount,
  });

  Map<String, dynamic> toJson() => {
        'total': total,
        'deltaPct': deltaPct,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'dow': dow,
        'peakHour': peakHour,
        'avgPerHead': avgPerHead,
        'styles': styles.map((e) => e.toJson()).toList(),
        'userCount': userCount,
      };

  factory StatsData.fromJson(Map<String, dynamic> json) => StatsData(
        total: (json['total'] as num).toInt(),
        deltaPct: (json['deltaPct'] as num).toInt(),
        timeline: (json['timeline'] as List)
            .map((e) => StatsTimelinePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        dow: (json['dow'] as List).map((e) => (e as num).toInt()).toList(),
        peakHour: json['peakHour'] as String? ?? '–',
        avgPerHead: (json['avgPerHead'] as num).toDouble(),
        styles: (json['styles'] as List)
            .map((e) => StatsStyleEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        userCount: (json['userCount'] as num).toInt(),
      );
}
