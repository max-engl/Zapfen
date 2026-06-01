import 'package:flutter/foundation.dart';
import '../models/drink_model.dart';
import '../services/drink_service.dart';

class DrinkProvider extends ChangeNotifier {
  final DrinkService _service;

  DrinkProvider(this._service);

  List<DrinkModel> _defaults = [];
  List<DrinkModel> _custom = [];
  bool _loading = false;
  String? _error;

  List<DrinkModel> get defaults => _defaults;
  List<DrinkModel> get custom => _custom;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.getDrinks();
      _defaults = result.defaults;
      _custom = result.custom;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<DrinkModel?> createCustom({
    required String name,
    String emoji = '🍺',
  }) async {
    try {
      final drink = await _service.createCustomDrink(
        name: name,
        emoji: emoji,
      );
      _custom = [drink, ..._custom];
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
      notifyListeners();
    } catch (_) {}
  }
}
