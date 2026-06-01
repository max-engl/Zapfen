import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../models/app_user.dart';

class AuthService {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthService(this._client, this._tokenStorage);

  Future<AppUser> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {'emailOrUsername': emailOrUsername, 'password': password},
    );
    final token = response.data['token'] as String;
    await _tokenStorage.saveAccessToken(token);
    return AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.register,
      data: {'username': username, 'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    await _tokenStorage.saveAccessToken(token);
    return AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser?> me() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      final response = await _client.dio.get(ApiConstants.me);
      return AppUser.fromJson(
        response.data['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clear();
      }
      return null;
    }
  }

  Future<void> logout() => _tokenStorage.clear();
}
