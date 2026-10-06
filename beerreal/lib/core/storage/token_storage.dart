import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'access_token';
  static const _userKey = 'cached_user';
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _tokenKey);

  Future<void> saveUser(Map<String, dynamic> json) =>
      _storage.write(key: _userKey, value: jsonEncode(json));

  Future<Map<String, dynamic>?> loadUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _userKey),
      ]);
}
