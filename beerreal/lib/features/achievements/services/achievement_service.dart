import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/achievement.dart';

class AchievementService {
  final ApiClient _apiClient;

  AchievementService(this._apiClient);

  Future<List<Achievement>> fetchMine() async {
    final res = await _apiClient.dio.get(ApiConstants.achievementsMe);
    final list = res.data['achievements'] as List<dynamic>;
    return list
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Achievement>> fetchForUser(String userId) async {
    final res = await _apiClient.dio.get(ApiConstants.achievementsForUser(userId));
    final list = res.data['achievements'] as List<dynamic>;
    return list
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendAchievementStanding>> fetchFriendStandings(
    String achievementId,
  ) async {
    final res = await _apiClient.dio.get(
      ApiConstants.achievementFriendStandings(achievementId),
    );
    final list = res.data['standings'] as List<dynamic>;
    return list
        .map((e) => FriendAchievementStanding.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AchievementLocationTarget>> fetchLocationTargets() async {
    final res = await _apiClient.dio.get(
      ApiConstants.achievementLocationTargets,
    );
    final list = res.data['targets'] as List<dynamic>;
    return list
        .map(
          (e) => AchievementLocationTarget.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
