import '../repositories/platform_notification_repository.dart';

class MarkAllPlatformNotificationsReadUseCase {
  const MarkAllPlatformNotificationsReadUseCase(this._repository);

  final PlatformNotificationRepository _repository;

  Future<void> call({int limit = 100}) {
    return _repository.markAllRead(limit: limit);
  }
}
