import '../entities/platform_notification.dart';
import '../repositories/platform_notification_repository.dart';

class WatchPlatformNotificationsUseCase {
  const WatchPlatformNotificationsUseCase(this._repository);

  final PlatformNotificationRepository _repository;

  Stream<List<PlatformNotification>> call({int limit = 80}) {
    return _repository.watchNotifications(limit: limit);
  }
}
