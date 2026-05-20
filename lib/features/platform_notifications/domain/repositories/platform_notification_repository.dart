import '../entities/platform_notification.dart';

abstract interface class PlatformNotificationRepository {
  Stream<List<PlatformNotification>> watchNotifications({int limit});

  Stream<int> watchUnreadCount();

  Future<void> markRead({
    required String notificationId,
    required bool isRead,
  });

  Future<void> markAllRead({int limit});
}
