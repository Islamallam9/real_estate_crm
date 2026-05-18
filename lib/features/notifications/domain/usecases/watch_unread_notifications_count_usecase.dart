import '../repositories/notification_repository.dart';

class WatchUnreadNotificationsCountUseCase {
  const WatchUnreadNotificationsCountUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<int> call({
    required String companyId,
    required String recipientUid,
  }) {
    return _repository.watchUnreadCount(
      companyId: companyId,
      recipientUid: recipientUid,
    );
  }
}
