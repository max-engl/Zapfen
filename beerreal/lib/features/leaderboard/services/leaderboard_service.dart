import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final ApiClient _apiClient;

  LeaderboardService(this._apiClient);

  Future<List<LeaderboardEntry>> fetchFriends() async {
    final res = await _apiClient.dio.get(ApiConstants.leaderboardFriends);
    final list = res.data['entries'] as List<dynamic>;
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeaderboardData> fetchGlobal() async {
    final res = await _apiClient.dio.get(ApiConstants.leaderboardGlobal);
    final list = res.data['entries'] as List<dynamic>;
    return LeaderboardData(
      entries: list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
      yourRank: (res.data['yourRank'] as num?)?.toInt() ?? 0,
      yourPercentile: res.data['yourPercentile'] as String? ?? '',
      totalUsers: (res.data['totalUsers'] as num?)?.toInt() ?? 0,
    );
  }
}
