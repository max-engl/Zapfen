import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/api_friend.dart';

class FriendService {
  final ApiClient _client;

  FriendService(this._client);

  Future<List<ApiFriend>> getFriends() async {
    final response = await _client.dio.get(ApiConstants.friends);
    final list = response.data['friends'] as List<dynamic>;
    return list.map((e) => ApiFriend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ApiFriendRequest>> getFriendRequests() async {
    final response = await _client.dio.get(ApiConstants.friendRequests);
    final list = response.data['requests'] as List<dynamic>;
    return list.map((e) => ApiFriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendFriendRequest(String userId) async {
    await _client.dio.post(ApiConstants.sendFriendRequest(userId));
  }

  Future<void> acceptFriendRequest(String userId) async {
    await _client.dio.post(ApiConstants.acceptFriendRequest(userId));
  }

  Future<void> removeFriend(String userId) async {
    await _client.dio.delete(ApiConstants.removeFriend(userId));
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    final response = await _client.dio.get(
      ApiConstants.searchUsers,
      queryParameters: {'q': query.trim()},
    );
    final list = response.data['users'] as List<dynamic>;
    return list.map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> getInviteLink() async {
    final response = await _client.dio.get(ApiConstants.myInvite);
    return response.data['link'] as String;
  }

  Future<Map<String, dynamic>> resolveInviteToken(String token) async {
    final response = await _client.dio.get(ApiConstants.resolveInvite(token));
    return response.data as Map<String, dynamic>;
  }

  Future<void> acceptInviteToken(String token) async {
    await _client.dio.post(ApiConstants.acceptInvite(token));
  }

  Future<List<FriendRecommendation>> getRecommendations() async {
    final response = await _client.dio.get(ApiConstants.friendRecommendations);
    final list = response.data['recommendations'] as List<dynamic>;
    return list
        .map((e) => FriendRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
