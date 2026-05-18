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
    this.message,
    this.reminderMessage,
    this.markingNotificationId = '',
    this.markingAllRead = false,
  });

  const NotificationsState.initial()
      : status = NotificationsStatus.initial,
        notifications = const [],
        reminders = const [],
        unreadCount = 0,
        message = null,
        reminderMessage = null,
        markingNotificationId = '',
        markingAllRead = false;

  final NotificationsStatus status;
  final List<CrmNotification> notifications;
  final List<AttentionReminder> reminders;
  final int unreadCount;
  final String? message;
  final String? reminderMessage;
  final String markingNotificationId;
  final bool markingAllRead;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<CrmNotification>? notifications,
    List<AttentionReminder>? reminders,
    int? unreadCount,
    String? message,
    String? reminderMessage,
    String? markingNotificationId,
    bool? markingAllRead,
    bool clearMessage = false,
    bool clearReminderMessage = false,
    bool clearMarkingNotificationId = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      reminders: reminders ?? this.reminders,
      unreadCount: unreadCount ?? this.unreadCount,
      message: clearMessage ? null : message ?? this.message,
      reminderMessage:
          clearReminderMessage ? null : reminderMessage ?? this.reminderMessage,
      markingNotificationId: clearMarkingNotificationId
          ? ''
          : markingNotificationId ?? this.markingNotificationId,
      markingAllRead: markingAllRead ?? this.markingAllRead,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        reminders,
        unreadCount,
        message,
        reminderMessage,
        markingNotificationId,
        markingAllRead,
      ];
}
