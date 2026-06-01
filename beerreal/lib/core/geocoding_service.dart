import 'package:dio/dio.dart';

class GeocodingService {
  GeocodingService._();

  static final _cache = <String, String>{};
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Returns the city (or nearest locality) for the given coordinates.
  /// Results are cached in-memory for the lifetime of the app.
  static Future<String?> cityName(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lng, 'format': 'json'},
        options: Options(headers: {'User-Agent': 'Zapfen/1.0'}),
      );
      final address = (res.data?['address'] as Map<String, dynamic>?) ?? {};
      final city = (address['city'] ?? address['town'] ?? address['village'] ?? address['county']) as String?;
      if (city != null) _cache[key] = city;
      return city;
    } catch (_) {
      return null;
    }
  }
}
