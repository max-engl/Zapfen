import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/app_notification.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService(this._apiClient);

  Future<List<AppNotification>> fetchNotifications() async {
    final res = await _apiClient.dio.get(ApiConstants.notifications);
    final list = res.data['notifications'] as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async {
    await _apiClient.dio.put(ApiConstants.notificationsReadAll);
  }

  Future<void> markRead(String id) async {
    await _apiClient.dio.put(ApiConstants.notificationRead(id));
  }
}
