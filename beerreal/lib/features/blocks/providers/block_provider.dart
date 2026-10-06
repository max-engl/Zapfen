import 'package:flutter/foundation.dart';
import '../services/block_service.dart';

class BlockProvider extends ChangeNotifier {
  final BlockService _service;

  BlockProvider(this._service);

  final Set<String> _blockedIds = {};
  bool _loading = false;

  Set<String> get blockedIds => _blockedIds;
  bool get loading => _loading;

  bool isBlocked(String userId) => _blockedIds.contains(userId);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final ids = await _service.getBlockedIds();
      _blockedIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> blockUser(String userId) async {
    await _service.blockUser(userId);
    _blockedIds.add(userId);
    notifyListeners();
  }

  Future<void> unblockUser(String userId) async {
    await _service.unblockUser(userId);
    _blockedIds.remove(userId);
    notifyListeners();
  }
}
