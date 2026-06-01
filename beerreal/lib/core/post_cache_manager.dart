import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches pre-signed image URLs so they don't have to be resolved again within
/// their validity window. Feed post data is handled by [FeedDatabase].
class PostCacheManager {
  static const String _urlCacheKey = 'pint_url_cache';
  static const Duration _urlCacheDuration = Duration(hours: 48);

  final SharedPreferences _prefs;

  PostCacheManager(this._prefs);

  /// Merges [urls] into the persistent URL cache.
  Future<void> cacheUrls(Map<String, String> urls) async {
    try {
      final existing = _getUrlCache();
      existing.addAll(urls);

      final encoded = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'urls': existing,
      });

      await _prefs.setString(_urlCacheKey, encoded);
    } catch (_) {}
  }

  /// Returns a cached URL for [key] if still within the 48-hour window.
  String? getCachedUrl(String key) {
    try {
      return _getUrlCache()[key];
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _getUrlCache() {
    try {
      final cached = _prefs.getString(_urlCacheKey);
      if (cached == null) return {};

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int? ?? 0;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (age < _urlCacheDuration) {
        return (decoded['urls'] as Map<String, dynamic>?) ?? {};
      }

      _prefs.remove(_urlCacheKey);
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> clearAll() async {
    await _prefs.remove(_urlCacheKey);
  }
}
