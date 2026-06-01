import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _service;

  NotificationProvider(this._service);

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _service.fetchNotifications();
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
    try {
      await _service.markAllRead();
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n == null || n.read) return;
    n.read = true;
    notifyListeners();
    try {
      await _service.markRead(id);
    } catch (_) {}
  }

  void onNewNotification() {
    load();
  }
}
