import '../../../../core/constants/role_constants.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Stream<List<CrmNotification>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
  }) {
    return _remoteDataSource.watchNotifications(
      companyId: companyId,
      recipientUid: recipientUid,
      limit: limit,
    );
  }

  @override
  Stream<int> watchUnreadCount({
    required String companyId,
    required String recipientUid,
  }) {
    return _remoteDataSource.watchUnreadCount(
      companyId: companyId,
      recipientUid: recipientUid,
    );
  }

  @override
  Stream<List<AttentionReminder>> watchAttentionReminders({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int limit = notificationMarkAllReadLimit,
  }) {
    return _remoteDataSource.watchAttentionReminders(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: limit,
    );
  }

  @override
  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  }) {
    return _remoteDataSource.markAsRead(
      companyId: companyId,
      notificationId: notificationId,
    );
  }

  @override
  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit = 60,
  }) {
    return _remoteDataSource.markAllRead(
      companyId: companyId,
      recipientUid: recipientUid,
      limit: limit,
    );
  }
}
