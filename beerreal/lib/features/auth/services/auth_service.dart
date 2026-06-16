import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/app_version.dart';
import '../../../core/storage/token_storage.dart';
import '../models/app_update_info.dart';
import '../models/app_user.dart';

class AuthService {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthService(this._client, this._tokenStorage);

  Future<({AppUser user, AppUpdateInfo updateInfo})> login({
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
    final user = AppUser.fromJson(
      response.data['user'] as Map<String, dynamic>,
    );
    await _tokenStorage.saveUser(user.toJson());
    return (
      user: user,
      updateInfo: AppUpdateInfo.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<({AppUser user, AppUpdateInfo updateInfo})> register({
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
    final user = AppUser.fromJson(
      response.data['user'] as Map<String, dynamic>,
    );
    await _tokenStorage.saveUser(user.toJson());
    return (
      user: user,
      updateInfo: AppUpdateInfo.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<AppUpdateInfo> versionPolicy() async {
    final response = await _client.dio.get(
      ApiConstants.authVersion,
      queryParameters: {'v': kAppVersion},
    );
    return AppUpdateInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<({AppUser? user, AppUpdateInfo updateInfo})> me() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      return (user: null, updateInfo: AppUpdateInfo.none);
    }
    try {
      final response = await _client.dio.get(
        ApiConstants.me,
        queryParameters: {'v': kAppVersion},
      );
      final user = AppUser.fromJson(
        response.data['user'] as Map<String, dynamic>,
      );
      await _tokenStorage.saveUser(user.toJson());
      return (
        user: user,
        updateInfo: AppUpdateInfo.fromJson(
          response.data as Map<String, dynamic>,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token rejected by server — clear everything and force login.
        await _tokenStorage.clear();
        return (user: null, updateInfo: AppUpdateInfo.none);
      }
      // Network error (server offline, timeout, etc.) — use cached user so the
      // app can run in offline mode with the last-known identity.
      final cached = await _tokenStorage.loadUser();
      if (cached != null) {
        return (user: AppUser.fromJson(cached), updateInfo: AppUpdateInfo.none);
      }
      return (user: null, updateInfo: AppUpdateInfo.none);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.dio.post(ApiConstants.forgotPassword, data: {'email': email});
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

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {
      // Best-effort — if the request fails (offline, 401) we still clear locally.
    }
    await _tokenStorage.clear();
  }
}
