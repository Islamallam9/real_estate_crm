import 'package:equatable/equatable.dart';

import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    required this.status,
    required this.notifications,
    required this.reminders,
    required this.unreadCount,
    this.notificationsLimit = 15,
    this.message,
    this.reminderMessage,
    this.markingNotificationId = '',
    this.markingAllRead = false,
    this.clearedNotificationIds = const <String>{},
    this.clearedReminderIds = const <String>{},
  });

  const NotificationsState.initial()
      : status = NotificationsStatus.initial,
        notifications = const [],
        reminders = const [],
        unreadCount = 0,
        notificationsLimit = 15,
        message = null,
        reminderMessage = null,
        markingNotificationId = '',
        markingAllRead = false,
        clearedNotificationIds = const <String>{},
        clearedReminderIds = const <String>{};

  final NotificationsStatus status;
  final List<CrmNotification> notifications;
  final List<AttentionReminder> reminders;
  final int unreadCount;
  final int notificationsLimit;
  final String? message;
  final String? reminderMessage;
  final String markingNotificationId;
  final bool markingAllRead;
  final Set<String> clearedNotificationIds;
  final Set<String> clearedReminderIds;

  int get visibleUnreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  int get effectiveUnreadCount {
    return unreadCount > visibleUnreadCount ? unreadCount : visibleUnreadCount;
  }

  int get effectiveBadgeCount => effectiveUnreadCount;

  bool get hasUnreadNotifications => effectiveUnreadCount > 0;

  bool get canLoadMoreNotifications => notifications.length >= notificationsLimit;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<CrmNotification>? notifications,
    List<AttentionReminder>? reminders,
    int? unreadCount,
    int? notificationsLimit,
    String? message,
    String? reminderMessage,
    String? markingNotificationId,
    bool? markingAllRead,
    Set<String>? clearedNotificationIds,
    Set<String>? clearedReminderIds,
    bool clearMessage = false,
    bool clearReminderMessage = false,
    bool clearMarkingNotificationId = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      reminders: reminders ?? this.reminders,
      unreadCount: unreadCount ?? this.unreadCount,
      notificationsLimit: notificationsLimit ?? this.notificationsLimit,
      message: clearMessage ? null : message ?? this.message,
      reminderMessage:
          clearReminderMessage ? null : reminderMessage ?? this.reminderMessage,
      markingNotificationId: clearMarkingNotificationId
          ? ''
          : markingNotificationId ?? this.markingNotificationId,
      markingAllRead: markingAllRead ?? this.markingAllRead,
      clearedNotificationIds:
          clearedNotificationIds ?? this.clearedNotificationIds,
      clearedReminderIds: clearedReminderIds ?? this.clearedReminderIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        reminders,
        unreadCount,
        notificationsLimit,
        message,
        reminderMessage,
        markingNotificationId,
        markingAllRead,
        clearedNotificationIds,
        clearedReminderIds,
      ];
}
