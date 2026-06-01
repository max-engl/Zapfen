import 'package:dio/dio.dart';
import 'api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            // Enable aggressive caching
            'Cache-Control': 'max-age=3600',
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
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
