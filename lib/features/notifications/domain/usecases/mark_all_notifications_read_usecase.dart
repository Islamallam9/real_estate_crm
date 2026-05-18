import '../constants/notification_limits.dart';
import '../repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call({
    required String companyId,
    required String recipientUid,
    int limit = notificationMarkAllReadLimit,
  }) {
    return _repository.markAllRead(
      companyId: companyId,
      recipientUid: recipientUid,
      limit: limit,
    );
  }
}
