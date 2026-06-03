import 'package:flutter/foundation.dart';
import '../models/stats_data.dart';
import '../services/stats_service.dart';

class StatsProvider extends ChangeNotifier {
  final StatsService _service;
  StatsProvider(this._service);

  final Map<String, StatsData> _cache = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  StatsData? dataFor(String scope, String range) => _cache['$scope:$range'];

  Future<void> load(String scope, String range) async {
    final key = '$scope:$range';
    if (_cache.containsKey(key)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cache[key] = await _service.fetch(scope: scope, range: range);
    } catch (_) {
      _error = 'Statistiken konnten nicht geladen werden.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String scope, String range) async {
    _cache.remove('$scope:$range');
    await load(scope, range);
  }
}
