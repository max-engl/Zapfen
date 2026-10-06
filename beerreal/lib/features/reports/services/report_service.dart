import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    await _apiClient.dio.post(
      ApiConstants.reportPost(postId),
      data: {'reason': reason},
    );
  }
}
