import 'package:flutter/foundation.dart';
import '../models/stats_data.dart';
import '../services/stats_service.dart';
import '../../../core/json_cache.dart';

class StatsProvider extends ChangeNotifier {
  final StatsService _service;
  final JsonCache _cache;

  StatsProvider(this._service, this._cache);

  final Map<String, StatsData> _memCache = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  StatsData? dataFor(String scope, String range) => _memCache['$scope:$range'];

  static String _cacheKey(String scope, String range) =>
      'pint_stats_${scope}_$range';

  /// Restore all previously cached (scope, range) combos from SharedPreferences.
  void preloadFromCache() {
    for (final scope in ['me', 'friends']) {
      for (final range in ['week', 'month', 'year', 'all']) {
        final key = _cacheKey(scope, range);
        final map = _cache.loadMap(key);
        if (map != null) {
          try {
            _memCache['$scope:$range'] = StatsData.fromJson(map);
          } catch (_) {}
        }
      }
    }
    if (_memCache.isNotEmpty) notifyListeners();
  }

  Future<void> load(String scope, String range) async {
    final key = '$scope:$range';
    if (_memCache.containsKey(key)) {
      // Already in memory (either from cache preload or a previous fetch).
      // Refresh in background without showing a spinner.
      _fetchAndUpdate(scope, range);
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    await _fetchAndUpdate(scope, range);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String scope, String range) async {
    _memCache.remove('$scope:$range');
    await load(scope, range);
  }

  Future<void> _fetchAndUpdate(String scope, String range) async {
    try {
      final fresh = await _service.fetch(scope: scope, range: range);
      _memCache['$scope:$range'] = fresh;
      _cache.saveMap(_cacheKey(scope, range), fresh.toJson());
      notifyListeners();
    } catch (_) {
      _error = 'Statistiken konnten nicht geladen werden.';
    }
  }
}
