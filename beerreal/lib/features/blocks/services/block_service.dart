import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class BlockService {
  final ApiClient _api;

  BlockService(this._api);

  Future<void> blockUser(String userId) async {
    await _api.dio.post(ApiConstants.blockUser(userId));
  }

  Future<void> unblockUser(String userId) async {
    await _api.dio.delete(ApiConstants.blockUser(userId));
  }

  Future<List<String>> getBlockedIds() async {
    final response = await _api.dio.get(ApiConstants.blocks);
    final data = response.data as Map<String, dynamic>;
    return List<String>.from(data['blockedIds'] as List);
  }
}
