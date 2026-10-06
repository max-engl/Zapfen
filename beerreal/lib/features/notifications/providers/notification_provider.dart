import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_api_service.dart';
import '../../../core/json_cache.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _service;
  final JsonCache _cache;

  NotificationProvider(this._service, this._cache);

  static const _cacheKey = 'pint_notifications';

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Restore from SharedPreferences — instant, no spinner.
  void preloadFromCache() {
    final rows = _cache.loadList(_cacheKey);
    if (rows != null && rows.isNotEmpty) {
      try {
        _notifications = rows.map(AppNotification.fromJson).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> load() async {
    _error = null;

    // Only show spinner when there's nothing cached to display.
    if (_notifications.isEmpty) {
      _loading = true;
      notifyListeners();
    }

    try {
      final fresh = await _service.fetchNotifications();
      _notifications = fresh;
      _cache.saveList(_cacheKey, fresh.map((n) => n.toJson()).toList());
    } catch (_) {
      _error = 'Benachrichtigungen konnten nicht geladen werden.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
    _cache.saveList(_cacheKey, _notifications.map((n) => n.toJson()).toList());
    try {
      await _service.markAllRead();
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n == null || n.read) return;
    n.read = true;
    notifyListeners();
    _cache.saveList(_cacheKey, _notifications.map((n) => n.toJson()).toList());
    try {
      await _service.markRead(id);
    } catch (_) {}
  }

  void onNewNotification() {
    load();
  }
}
