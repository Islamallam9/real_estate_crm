import 'package:equatable/equatable.dart';

import '../../domain/entities/platform_notification.dart';

enum PlatformNotificationsStatus { initial, loading, ready, failure }

enum PlatformNotificationFilter { all, unread, urgent, support, company, invitation, storage }

class PlatformNotificationsState extends Equatable {
  const PlatformNotificationsState({
    required this.status,
    this.notifications = const [],
    this.unreadCount = 0,
    this.filter = PlatformNotificationFilter.all,
    this.markingNotificationId = '',
    this.markingAllRead = false,
    this.message,
  });

  const PlatformNotificationsState.initial()
      : this(status: PlatformNotificationsStatus.initial);

  final PlatformNotificationsStatus status;
  final List<PlatformNotification> notifications;
  final int unreadCount;
  final PlatformNotificationFilter filter;
  final String markingNotificationId;
  final bool markingAllRead;
  final String? message;

  List<PlatformNotification> get filteredNotifications {
    return notifications.where((notification) {
      return switch (filter) {
        PlatformNotificationFilter.all => true,
        PlatformNotificationFilter.unread => !notification.isRead,
        PlatformNotificationFilter.urgent =>
          notification.severity == PlatformNotificationSeverity.urgent,
        PlatformNotificationFilter.support =>
          notification.source == PlatformNotificationSource.support,
        PlatformNotificationFilter.company =>
          notification.source == PlatformNotificationSource.company ||
              notification.source == PlatformNotificationSource.user,
        PlatformNotificationFilter.invitation =>
          notification.source == PlatformNotificationSource.invitation,
        PlatformNotificationFilter.storage =>
          notification.source == PlatformNotificationSource.storage,
      };
    }).toList(growable: false);
  }

  PlatformNotificationsState copyWith({
    PlatformNotificationsStatus? status,
    List<PlatformNotification>? notifications,
    int? unreadCount,
    PlatformNotificationFilter? filter,
    String? markingNotificationId,
    bool? markingAllRead,
    String? message,
    bool clearMarkingNotificationId = false,
    bool clearMessage = false,
  }) {
    return PlatformNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter ?? this.filter,
      markingNotificationId: clearMarkingNotificationId
          ? ''
          : markingNotificationId ?? this.markingNotificationId,
      markingAllRead: markingAllRead ?? this.markingAllRead,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        filter,
        markingNotificationId,
        markingAllRead,
        message,
      ];
}
