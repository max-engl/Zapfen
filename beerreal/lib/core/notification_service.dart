import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api/api_client.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenRefreshSub;

  /// Call once from main() after Firebase.initializeApp().
  /// Wires up local notification display for foreground messages.
  static Future<void> init() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    _doSetup(apiClient).catchError((_) {});
  }

  static Future<void> _doSetup(ApiClient apiClient) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Push permission: ${settings.authorizationStatus}');

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
