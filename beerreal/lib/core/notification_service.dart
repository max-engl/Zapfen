import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenRefreshSub;
  // Deliberately not a `pint_` cache key: this device preference should
  // survive logout and app-data cache cleanup.
  static const preferenceKey = 'push_notifications_enabled';
  static bool _enabled = true;

  static bool get enabled => _enabled;

  /// Call once from main() after Firebase.initializeApp().
  /// Wires up local notification display for foreground messages.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(preferenceKey) ?? true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_enabled) return;
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'default',
            'Benachrichtigungen',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Call after the user is authenticated (e.g. in PintApp.initState).
  /// Runs entirely in the background — never blocks the UI thread.
  static void setupPermissions(ApiClient apiClient) {
    if (!_enabled) return;
    _doSetup(apiClient).catchError((_) => false);
  }

  /// Enables or disables push delivery for this account and device.
  ///
  /// Returns false only when enabling was rejected by the operating system.
  static Future<bool> setEnabled(ApiClient apiClient, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      _enabled = false;
      await prefs.setBool(preferenceKey, false);
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      try {
        await apiClient.dio.delete('/users/me/fcm-token');
      } on DioException {
        // Deleting the local token still prevents delivery to this app
        // instance. The backend also removes stale tokens after a failed send.
      }
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
      return true;
    }

    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final authorized = await _doSetup(apiClient);
    _enabled = authorized;
    await prefs.setBool(preferenceKey, authorized);
    if (!authorized) {
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
      } catch (_) {}
    }
    return authorized;
  }

  static Future<bool> _doSetup(ApiClient apiClient) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Push permission: ${settings.authorizationStatus}');
    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!authorized) return false;

    // APNs token must be available before FCM can deliver via APNs on iOS.
    final apns = await messaging.getAPNSToken();
    debugPrint('APNs token: $apns');

    final fcm = await messaging.getToken();
    debugPrint('FCM token: $fcm');

    if (fcm != null) {
      await _registerToken(apiClient, fcm);
    }

    // Re-register whenever the token rotates. Cancel any previous listener first.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (newToken) => _registerToken(apiClient, newToken),
    );
    return true;
  }

  static Future<void> _registerToken(ApiClient apiClient, String token) async {
    try {
      await apiClient.dio.put('/users/me/fcm-token', data: {'fcmToken': token});
      debugPrint('FCM token registered with backend');
    } on DioException catch (e) {
      debugPrint('Failed to register FCM token: ${e.message}');
    }
  }
}
