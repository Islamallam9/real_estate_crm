import '../repositories/platform_notification_repository.dart';

class MarkPlatformNotificationReadUseCase {
  const MarkPlatformNotificationReadUseCase(this._repository);

  final PlatformNotificationRepository _repository;

  Future<void> call({
    required String notificationId,
    required bool isRead,
  }) {
    return _repository.markRead(
      notificationId: notificationId,
      isRead: isRead,
    );
  }
}
