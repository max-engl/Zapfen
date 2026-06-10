import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/app_version.dart';
import '../../../core/storage/token_storage.dart';
import '../models/app_user.dart';

class AuthService {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthService(this._client, this._tokenStorage);

  Future<({AppUser user, bool updateRequired, List<String> patchNotes})> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {
        'emailOrUsername': emailOrUsername,
        'password': password,
        'clientVersion': kAppVersion,
      },
    );
    final token = response.data['token'] as String;
    await _tokenStorage.saveAccessToken(token);
    return (
      user: AppUser.fromJson(response.data['user'] as Map<String, dynamic>),
      updateRequired: response.data['updateRequired'] as bool? ?? false,
      patchNotes: _parsePatchNotes(response.data['patchNotes']),
    );
  }

  Future<({AppUser user, bool updateRequired, List<String> patchNotes})> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'clientVersion': kAppVersion,
      },
    );
    final token = response.data['token'] as String;
    await _tokenStorage.saveAccessToken(token);
    return (
      user: AppUser.fromJson(response.data['user'] as Map<String, dynamic>),
      updateRequired: response.data['updateRequired'] as bool? ?? false,
      patchNotes: _parsePatchNotes(response.data['patchNotes']),
    );
  }

  Future<({AppUser? user, bool updateRequired, List<String> patchNotes})> me() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return (user: null, updateRequired: false, patchNotes: <String>[]);
    try {
      final response = await _client.dio.get(
        ApiConstants.me,
        queryParameters: {'v': kAppVersion},
      );
      return (
        user: AppUser.fromJson(response.data['user'] as Map<String, dynamic>),
        updateRequired: response.data['updateRequired'] as bool? ?? false,
        patchNotes: _parsePatchNotes(response.data['patchNotes']),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clear();
      }
      return (user: null, updateRequired: false, patchNotes: <String>[]);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.dio.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> logout() => _tokenStorage.clear();

  static List<String> _parsePatchNotes(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }
}
