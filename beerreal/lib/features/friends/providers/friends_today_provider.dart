import 'package:flutter/foundation.dart';
import '../models/friends_today.dart';
import '../services/friend_service.dart';

/// Who in the circle has already poured today — backs the "Friends today"
/// home-screen widget (and can be surfaced in-app later).
class FriendsTodayProvider extends ChangeNotifier {
  final FriendService _friendService;

  FriendsTodayProvider(this._friendService);

  FriendsToday _data = FriendsToday.empty;
  bool _loading = false;

  FriendsToday get data => _data;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _data = await _friendService.getFriendsPouredToday();
    } catch (_) {
      // keep previous data on failure
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
