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

  StatsData? dataFor(String scope, String range, int offset) =>
      _memCache['$scope:$range:$offset'];

  static String _cacheKey(String scope, String range, int offset) =>
      'pint_stats_${scope}_${range}_$offset';

  void preloadFromCache() {
    for (final scope in ['friends', 'global']) {
      for (final range in ['week', 'month', 'year']) {
        final key = _cacheKey(scope, range, 0);
        final map = _cache.loadMap(key);
        if (map != null) {
          try {
            _memCache['$scope:$range:0'] = StatsData.fromJson(map);
          } catch (_) {}
        }
      }
    }
    if (_memCache.isNotEmpty) notifyListeners();
  }

  Future<void> load(String scope, String range, int offset) async {
    final key = '$scope:$range:$offset';
    if (_memCache.containsKey(key)) {
      _fetchAndUpdate(scope, range, offset);
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    await _fetchAndUpdate(scope, range, offset);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String scope, String range, int offset) async {
    _memCache.remove('$scope:$range:$offset');
    await load(scope, range, offset);
  }

  Future<void> _fetchAndUpdate(String scope, String range, int offset) async {
    try {
      final fresh = await _service.fetch(scope: scope, range: range, offset: offset);
      _memCache['$scope:$range:$offset'] = fresh;
      _cache.saveMap(_cacheKey(scope, range, offset), fresh.toJson());
      notifyListeners();
    } catch (_) {
      _error = 'Statistiken konnten nicht geladen werden.';
    }
  }
}
