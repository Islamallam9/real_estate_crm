import '../../../../core/constants/role_constants.dart';
import '../entities/attention_reminder.dart';
import '../entities/crm_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<CrmNotification>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit,
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
    int limit,
  });

  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  });

  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit,
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
