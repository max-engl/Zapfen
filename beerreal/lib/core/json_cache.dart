import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for storing JSON blobs.
/// Silently swallows all errors — cache misses are never fatal.
class JsonCache {
  final SharedPreferences _prefs;
  const JsonCache(this._prefs);

  Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    try {
      await _prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  List<Map<String, dynamic>>? loadList(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return null;
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMap(String key, Map<String, dynamic> data) async {
    try {
      await _prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  Map<String, dynamic>? loadMap(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (_) {}
  }
}
