import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../../../core/json_cache.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _service;
  final JsonCache _cache;

  AchievementProvider(this._service, this._cache);

  static const _cacheKey = 'pint_achievements';

  List<Achievement> _achievements = [];
  bool _loading = false;
  String? _error;

  List<Achievement> get achievements => _achievements;
  bool get loading => _loading;
  String? get error => _error;
  int get earnedCount => _achievements.where((a) => a.earned).length;

  /// Restore from SharedPreferences — instant, no spinner.
  void preloadFromCache() {
    final rows = _cache.loadList(_cacheKey);
    if (rows != null && rows.isNotEmpty) {
      try {
        _achievements = rows.map(Achievement.fromJson).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> load() async {
    if (_loading) return;
    _error = null;

    // Only show spinner when there's nothing cached to display.
    if (_achievements.isEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      final fresh = await _service.fetchMine();
      _achievements = fresh;
      _cache.saveList(_cacheKey, fresh.map((a) => a.toJson()).toList());
    } catch (_) {
      _error = 'Erfolge konnten nicht geladen werden.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _achievements = [];
    await load();
  }
}
