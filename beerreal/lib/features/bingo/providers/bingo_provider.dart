import 'package:flutter/foundation.dart';
import '../services/bingo_service.dart';

class BingoProvider extends ChangeNotifier {
  final BingoService _service;

  BingoProvider(this._service);

  BingoCard? _card;
  bool _loading = false;

  BingoCard? get card => _card;
  bool get loading => _loading;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    _card = await _service.fetchCard();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _card = null;
    await load();
  }
}
