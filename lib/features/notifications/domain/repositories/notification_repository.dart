import '../../../../core/constants/role_constants.dart';
import '../constants/notification_limits.dart';
import '../entities/attention_reminder.dart';
import '../entities/crm_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<CrmNotification>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
  });

  Stream<int> watchUnreadCount({
    required String companyId,
    required String recipientUid,
  });

  Stream<List<AttentionReminder>> watchAttentionReminders({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int limit = notificationMarkAllReadLimit,
  });

  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  });

  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit = 60,
  });

  Future<void> markResolved({
    required String companyId,
    required String notificationId,
  });

  Future<void> dismiss({
    required String companyId,
    required String notificationId,
  });
}
