import 'package:flutter/foundation.dart';
import '../services/bingo_service.dart';
import '../../../core/json_cache.dart';

class BingoProvider extends ChangeNotifier {
  final BingoService _service;
  final JsonCache _cache;

  BingoProvider(this._service, this._cache);

  static const _cacheKey = 'pint_bingo_card';

  BingoCard? _card;
  bool _loading = false;

  BingoCard? get card => _card;
  bool get loading => _loading;

  /// Restore from SharedPreferences — instant, no spinner.
  void preloadFromCache() {
    final map = _cache.loadMap(_cacheKey);
    if (map != null) {
      try {
        _card = BingoCard.fromJson(map);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> load() async {
    if (_loading) return;

    // Only show spinner when there's nothing cached to display.
    if (_card == null) {
      _loading = true;
      notifyListeners();
    }

    final fresh = await _service.fetchCard();
    if (fresh != null) {
      _card = fresh;
      _cache.saveMap(_cacheKey, fresh.toJson());
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _card = null;
    await load();
  }
}
