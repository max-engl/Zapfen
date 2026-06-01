import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _service;

  LeaderboardProvider(this._service);

  List<LeaderboardEntry> _friendEntries = [];
  List<LeaderboardEntry> _globalEntries = [];
  int _yourGlobalRank = 0;
  String _yourPercentile = '';
  int _totalUsers = 0;
  bool _loading = false;
  String? _error;

  List<LeaderboardEntry> get friendEntries => _friendEntries;
  List<LeaderboardEntry> get globalEntries => _globalEntries;
  int get yourGlobalRank => _yourGlobalRank;
  String get yourPercentile => _yourPercentile;
  int get totalUsers => _totalUsers;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchFriends(),
        _service.fetchGlobal(),
      ]);
      _friendEntries = results[0] as List<LeaderboardEntry>;
      final globalData = results[1] as LeaderboardData;
      _globalEntries = globalData.entries;
      _yourGlobalRank = globalData.yourRank;
      _yourPercentile = globalData.yourPercentile;
      _totalUsers = globalData.totalUsers;
    } catch (e) {
      _error = 'Could not load leaderboard.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _friendEntries = [];
    _globalEntries = [];
    await load();
  }

  List<LeaderboardEntry> sorted(String board, String metric) {
    final src = board == 'friends' ? _friendEntries : _globalEntries;
    final copy = List.of(src);
    copy.sort((a, b) => b.valueFor(metric).compareTo(a.valueFor(metric)));
    return copy;
  }
}
