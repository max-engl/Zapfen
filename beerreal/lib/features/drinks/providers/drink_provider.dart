import 'package:flutter/foundation.dart';
import '../models/drink_model.dart';
import '../services/drink_service.dart';
import '../../../core/json_cache.dart';

class DrinkProvider extends ChangeNotifier {
  final DrinkService _service;
  final JsonCache _cache;

  DrinkProvider(this._service, this._cache);

  static const _defaultsKey = 'pint_drinks_defaults';
  static const _customKey = 'pint_drinks_custom';

  List<DrinkModel> _defaults = [];
  List<DrinkModel> _custom = [];
  bool _loading = false;
  String? _error;

  List<DrinkModel> get defaults => _defaults;
  List<DrinkModel> get custom => _custom;
  bool get loading => _loading;
  String? get error => _error;

  /// Restore from SharedPreferences — instant, no spinner.
  void preloadFromCache() {
    final defRows = _cache.loadList(_defaultsKey);
    final custRows = _cache.loadList(_customKey);
    if (defRows != null || custRows != null) {
      try {
        if (defRows != null) {
          _defaults = defRows.map((j) => DrinkModel.fromJson(j)).toList();
        }
        if (custRows != null) {
          _custom = custRows.map((j) => DrinkModel.fromJson(j)).toList();
        }
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> load() async {
    if (_loading) return;
    _error = null;

    // Only show spinner when there's nothing cached to display.
    if (_defaults.isEmpty && _custom.isEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      final result = await _service.getDrinks();
      _defaults = result.defaults;
      _custom = result.custom;
      _cache.saveList(_defaultsKey, _defaults.map((d) => d.toJson()).toList());
      _cache.saveList(_customKey, _custom.map((d) => d.toJson()).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<DrinkModel?> createCustom({
    required String name,
    String emoji = '🥤',
  }) async {
    try {
      final drink = await _service.createCustomDrink(
        name: name,
        emoji: emoji,
      );
      _custom = [drink, ..._custom];
      _cache.saveList(_customKey, _custom.map((d) => d.toJson()).toList());
      notifyListeners();
      return drink;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCustom(String drinkId) async {
    try {
      await _service.deleteDrink(drinkId);
      _custom = _custom.where((d) => d.id != drinkId).toList();
      _cache.saveList(_customKey, _custom.map((d) => d.toJson()).toList());
      notifyListeners();
    } catch (_) {}
  }
}
