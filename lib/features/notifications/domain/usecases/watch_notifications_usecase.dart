import '../entities/crm_notification.dart';
import '../repositories/notification_repository.dart';
import '../constants/notification_limits.dart';

class WatchNotificationsUseCase {
  const WatchNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<List<CrmNotification>> call({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
  }) {
    return _repository.watchNotifications(
      companyId: companyId,
      recipientUid: recipientUid,
      limit: limit,
    );
  }
}
