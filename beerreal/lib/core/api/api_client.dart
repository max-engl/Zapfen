import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Called when the server returns 401. Wire this up to AuthProvider.logout()
  /// so the app forces the user back to the login screen.
  VoidCallback? onUnauthorized;

  ApiClient(this._tokenStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Tz-Offset'] =
              DateTime.now().timeZoneOffset.inMinutes.toString();
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
