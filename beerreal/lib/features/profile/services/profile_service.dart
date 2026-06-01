import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../auth/models/app_user.dart';

class ProfileService {
  final ApiClient _client;
  ProfileService(this._client);

  Future<AppUser> updateUsername(String username) async {
    final res = await _client.dio.patch(
      ApiConstants.updateMe,
      data: {'username': username},
    );
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.put(
      ApiConstants.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<AppUser> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });
    final res = await _client.dio.patch(
      ApiConstants.updateAvatar,
      data: formData,
    );
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> removeAvatar() async {
    final res = await _client.dio.delete(ApiConstants.removeAvatar);
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }
}
