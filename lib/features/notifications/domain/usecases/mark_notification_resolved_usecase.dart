import '../repositories/notification_repository.dart';

class MarkNotificationResolvedUseCase {
  const MarkNotificationResolvedUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call({
    required String companyId,
    required String notificationId,
  }) {
    return _repository.markResolved(
      companyId: companyId,
      notificationId: notificationId,
    );
  }
}
