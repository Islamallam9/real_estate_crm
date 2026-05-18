import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call({
    required String companyId,
    required String notificationId,
  }) {
    return _repository.markAsRead(
      companyId: companyId,
      notificationId: notificationId,
    );
  }
}
