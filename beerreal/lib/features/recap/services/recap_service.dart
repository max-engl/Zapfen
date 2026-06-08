import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class RecapDrink {
  final String name;
  final String emoji;
  final int count;

  const RecapDrink({required this.name, required this.emoji, required this.count});

  factory RecapDrink.fromJson(Map<String, dynamic> j) => RecapDrink(
        name: j['name'] as String? ?? 'Sonstiges',
        emoji: j['emoji'] as String? ?? '🍺',
        count: (j['count'] as num?)?.toInt() ?? 1,
      );
}

class NightRecap {
  final int totalDrinks;
  final List<RecapDrink> drinks;
  final int uniqueLocations;
  final int totalReactions;

  const NightRecap({
    required this.totalDrinks,
    required this.drinks,
    required this.uniqueLocations,
    required this.totalReactions,
  });

  factory NightRecap.fromJson(Map<String, dynamic> j) => NightRecap(
        totalDrinks: (j['totalDrinks'] as num?)?.toInt() ?? 0,
        drinks: (j['drinks'] as List<dynamic>? ?? [])
            .map((d) => RecapDrink.fromJson(d as Map<String, dynamic>))
            .toList(),
        uniqueLocations: (j['uniqueLocations'] as num?)?.toInt() ?? 0,
        totalReactions: (j['totalReactions'] as num?)?.toInt() ?? 0,
      );
}

class RecapService {
  final ApiClient _api;

  const RecapService(this._api);

  Future<NightRecap?> getNightRecap() async {
    try {
      final res = await _api.dio.get(ApiConstants.nightRecap);
      final data = res.data as Map<String, dynamic>;
      if (data['hasRecap'] != true) return null;
      return NightRecap.fromJson(data);
    } on DioException {
      return null;
    }
  }
}
