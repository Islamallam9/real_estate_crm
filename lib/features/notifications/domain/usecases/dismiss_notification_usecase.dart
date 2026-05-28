import '../repositories/notification_repository.dart';

class DismissNotificationUseCase {
  const DismissNotificationUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call({
    required String companyId,
    required String notificationId,
  }) {
    return _repository.dismiss(
      companyId: companyId,
      notificationId: notificationId,
    );
  }
}
