import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../../../core/json_cache.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _service;
  final JsonCache _cache;

  LeaderboardProvider(this._service, this._cache);

  static const _friendsKey = 'pint_leaderboard_friends';
  static const _globalKey = 'pint_leaderboard_global';

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

  /// Load from SharedPreferences cache — no network, no spinner.
  void preloadFromCache() {
    final friends = _cache.loadList(_friendsKey);
    final globalMap = _cache.loadMap(_globalKey);
    if (friends != null && globalMap != null) {
      _friendEntries = friends.map(LeaderboardEntry.fromJson).toList();
      final entries = (globalMap['entries'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList();
      _globalEntries = entries;
      _yourGlobalRank = (globalMap['yourRank'] as num?)?.toInt() ?? 0;
      _yourPercentile = globalMap['yourPercentile'] as String? ?? '';
      _totalUsers = (globalMap['totalUsers'] as num?)?.toInt() ?? 0;
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (_loading) return;
    _error = null;

    // Only show spinner when there's nothing to display yet.
    if (_friendEntries.isEmpty && _globalEntries.isEmpty) {
      _loading = true;
      notifyListeners();
    }

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

      _cache.saveList(_friendsKey, _friendEntries.map((e) => e.toJson()).toList());
      _cache.saveMap(_globalKey, {
        'entries': _globalEntries.map((e) => e.toJson()).toList(),
        'yourRank': _yourGlobalRank,
        'yourPercentile': _yourPercentile,
        'totalUsers': _totalUsers,
      });
    } catch (e) {
      _error = 'Could not load leaderboard.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Refresh in the background — keeps existing data visible, updates silently.
  Future<void> refresh() async {
    await load();
  }

  List<LeaderboardEntry> sorted(String board, String metric) {
    final src = board == 'friends' ? _friendEntries : _globalEntries;
    final copy = List.of(src);
    copy.sort((a, b) => b.valueFor(metric).compareTo(a.valueFor(metric)));
    return copy;
  }
}
