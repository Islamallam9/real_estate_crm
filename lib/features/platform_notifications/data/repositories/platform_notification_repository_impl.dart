import '../../domain/entities/platform_notification.dart';
import '../../domain/repositories/platform_notification_repository.dart';
import '../datasources/platform_notifications_remote_data_source.dart';

class PlatformNotificationRepositoryImpl
    implements PlatformNotificationRepository {
  const PlatformNotificationRepositoryImpl({
    required PlatformNotificationsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PlatformNotificationsRemoteDataSource _remoteDataSource;

  @override
  Stream<List<PlatformNotification>> watchNotifications({int limit = 80}) {
    return _remoteDataSource.watchNotifications(limit: limit);
  }

  @override
  Stream<int> watchUnreadCount() {
    return _remoteDataSource.watchUnreadCount();
  }

  @override
  Future<void> markRead({
    required String notificationId,
    required bool isRead,
  }) {
    return _remoteDataSource.markRead(
      notificationId: notificationId,
      isRead: isRead,
    );
  }

  @override
  Future<void> markAllRead({int limit = 100}) {
    return _remoteDataSource.markAllRead(limit: limit);
  }
}
