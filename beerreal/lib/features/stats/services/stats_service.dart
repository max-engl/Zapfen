import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/stats_data.dart';

class StatsService {
  final ApiClient _apiClient;
  StatsService(this._apiClient);

  Future<StatsData> fetch({
    required String scope,
    required String range,
    int offset = 0,
  }) async {
    final res = await _apiClient.dio.get(
      ApiConstants.stats,
      queryParameters: {'scope': scope, 'range': range, 'offset': offset},
    );
    return StatsData.fromJson(res.data as Map<String, dynamic>);
  }
}
