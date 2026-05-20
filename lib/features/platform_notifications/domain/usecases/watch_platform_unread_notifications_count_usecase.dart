import '../repositories/platform_notification_repository.dart';

class WatchPlatformUnreadNotificationsCountUseCase {
  const WatchPlatformUnreadNotificationsCountUseCase(this._repository);

  final PlatformNotificationRepository _repository;

  Stream<int> call() {
    return _repository.watchUnreadCount();
  }
}
