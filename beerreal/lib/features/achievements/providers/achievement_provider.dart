import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _service;

  AchievementProvider(this._service);

  List<Achievement> _achievements = [];
  bool _loading = false;
  String? _error;

  List<Achievement> get achievements => _achievements;
  bool get loading => _loading;
  String? get error => _error;
  int get earnedCount => _achievements.where((a) => a.earned).length;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _achievements = await _service.fetchMine();
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
