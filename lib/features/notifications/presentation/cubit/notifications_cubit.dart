import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/errors/notification_exception.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/dismiss_notification_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_notification_resolved_usecase.dart';
import '../../domain/usecases/watch_attention_reminders_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';
import '../../domain/usecases/watch_unread_notifications_count_usecase.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required WatchNotificationsUseCase watchNotificationsUseCase,
    required WatchUnreadNotificationsCountUseCase watchUnreadCountUseCase,
    required WatchAttentionRemindersUseCase watchAttentionRemindersUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkNotificationResolvedUseCase markNotificationResolvedUseCase,
    required DismissNotificationUseCase dismissNotificationUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
  })  : _watchNotificationsUseCase = watchNotificationsUseCase,
        _watchUnreadCountUseCase = watchUnreadCountUseCase,
        _watchAttentionRemindersUseCase = watchAttentionRemindersUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markNotificationResolvedUseCase = markNotificationResolvedUseCase,
        _dismissNotificationUseCase = dismissNotificationUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        super(const NotificationsState.initial());

  final WatchNotificationsUseCase _watchNotificationsUseCase;
  final WatchUnreadNotificationsCountUseCase _watchUnreadCountUseCase;
  final WatchAttentionRemindersUseCase _watchAttentionRemindersUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkNotificationResolvedUseCase _markNotificationResolvedUseCase;
  final DismissNotificationUseCase _dismissNotificationUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;

  StreamSubscription<List<CrmNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<List<AttentionReminder>>? _remindersSubscription;
  String _sessionKey = '';
  String _notificationsKey = '';
  String _unreadCountKey = '';
  String _remindersKey = '';
  final Map<String, _AttentionWatchRequest> _attentionRequests =
      <String, _AttentionWatchRequest>{};
  final Set<String> _locallyReadNotificationIds = <String>{};
  DateTime? _suppressUnreadCountUntil;

  void refreshShell({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int notificationsLimit = notificationDropdownLimit,
  }) {
    _notificationsKey = '';
    _unreadCountKey = '';
    watchShell(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      notificationsLimit: notificationsLimit,
      clearExistingNotifications: true,
    );
  }

  void refreshCenter({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int notificationsLimit = notificationDropdownLimit,
    int remindersLimit = 60,
  }) {
    _notificationsKey = '';
    _unreadCountKey = '';
    _remindersKey = '';
    emit(
      state.copyWith(
        status: NotificationsStatus.loading,
        notifications: const <CrmNotification>[],
        reminders: const <AttentionReminder>[],
        clearMessage: true,
        clearReminderMessage: true,
        clearedNotificationIds: const <String>{},
        clearedReminderIds: const <String>{},
      ),
    );
    watchCenter(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      notificationsLimit: notificationsLimit,
      remindersLimit: remindersLimit,
    );
  }

  void watchShell({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int notificationsLimit = notificationDropdownLimit,
    bool clearExistingNotifications = false,
  }) {
    _prepareSession(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
    );
    _watchNotifications(
      companyId: companyId,
      currentUserId: currentUserId,
      notificationsLimit: notificationsLimit,
      clearExistingNotifications: clearExistingNotifications,
    );
    _watchUnreadCount(
      companyId: companyId,
      currentUserId: currentUserId,
    );
    if (_attentionRequests.isEmpty) {
      _stopAttentionReminders(clearState: true);
    }
  }

  void watchCenter({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int notificationsLimit = notificationDropdownLimit,
    int remindersLimit = 60,
  }) {
    watchShell(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      notificationsLimit: notificationsLimit,
    );
    watchAttentionReminders(
      consumerKey: 'notification-center',
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      remindersLimit: remindersLimit,
    );
  }

  void loadMoreCenter({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int pageIncrement = notificationHistoryPageLimit,
    int remindersLimit = 60,
  }) {
    if (state.status == NotificationsStatus.loading ||
        !state.canLoadMoreNotifications) {
      return;
    }
    watchCenter(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      notificationsLimit: state.notificationsLimit + pageIncrement,
      remindersLimit: remindersLimit,
    );
  }

  void watchAttentionReminders({
    required String consumerKey,
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int remindersLimit = 60,
  }) {
    _prepareSession(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
    );
    _attentionRequests[consumerKey] = _AttentionWatchRequest(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: remindersLimit,
    );
    _syncAttentionReminders();
  }

  void releaseAttentionReminders(String consumerKey) {
    if (_attentionRequests.remove(consumerKey) == null) {
      return;
    }
    _syncAttentionReminders();
  }

  void _prepareSession({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
  }) {
    final key = '$companyId:$currentUserId:${role.name}:${managerTeamId ?? ''}';
    if (_sessionKey == key) {
      return;
    }
    _sessionKey = key;
    _notificationsKey = '';
    _unreadCountKey = '';
    _remindersKey = '';
    _attentionRequests.clear();
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _stopAttentionReminders(clearState: true);
    _locallyReadNotificationIds.clear();
    _suppressUnreadCountUntil = null;
    if (!isClosed) {
      emit(const NotificationsState.initial());
    }
  }

  void _watchNotifications({
    required String companyId,
    required String currentUserId,
    required int notificationsLimit,
    bool clearExistingNotifications = false,
  }) {
    final key = '$companyId:$currentUserId:$notificationsLimit';
    if (_notificationsKey == key) {
      return;
    }
    _notificationsKey = key;
    _notificationsSubscription?.cancel();
    emit(
      state.copyWith(
        status: NotificationsStatus.loading,
        notifications: clearExistingNotifications
            ? const <CrmNotification>[]
            : state.notifications,
        notificationsLimit: notificationsLimit,
        clearMessage: true,
        clearedNotificationIds: clearExistingNotifications
            ? const <String>{}
            : state.clearedNotificationIds,
      ),
    );
    _notificationsSubscription = _watchNotificationsUseCase(
      companyId: companyId,
      recipientUid: currentUserId,
      limit: notificationsLimit,
    ).listen(
      (notifications) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            notifications: _applyLocalReadOverrides(
              _filterClearedNotifications(notifications),
            ),
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            message: _errorMessage(error),
          ),
        );
      },
    );
  }

  void _watchUnreadCount({
    required String companyId,
    required String currentUserId,
  }) {
    final key = '$companyId:$currentUserId';
    if (_unreadCountKey == key) {
      return;
    }
    _unreadCountKey = key;
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = _watchUnreadCountUseCase(
      companyId: companyId,
      recipientUid: currentUserId,
    ).listen(
      (count) {
        if (!isClosed) {
          final suppressUntil = _suppressUnreadCountUntil;
          final effectiveCount = suppressUntil != null &&
                  DateTime.now().isBefore(suppressUntil)
              ? 0
              : count;
          emit(state.copyWith(unreadCount: effectiveCount, clearMessage: true));
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(state.copyWith(message: _errorMessage(error)));
        }
      },
    );
  }

  void _syncAttentionReminders() {
    if (_attentionRequests.isEmpty) {
      _stopAttentionReminders(clearState: true);
      return;
    }
    final request = _attentionRequests.values.reduce(
      (current, next) => next.limit > current.limit ? next : current,
    );
    final key =
        '${request.companyId}:${request.currentUserId}:${request.role.name}:'
        '${request.managerTeamId ?? ''}:${request.limit}';
    if (_remindersKey == key) {
      return;
    }
    _remindersKey = key;
    _remindersSubscription?.cancel();
    _remindersSubscription = _watchAttentionRemindersUseCase(
      companyId: request.companyId,
      currentUserId: request.currentUserId,
      role: request.role,
      managerTeamId: request.managerTeamId,
      limit: request.limit,
    ).listen(
      (reminders) {
        if (!isClosed) {
          emit(
            state.copyWith(
              reminders: _filterClearedReminders(reminders),
              clearReminderMessage: true,
            ),
          );
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(state.copyWith(reminderMessage: _errorMessage(error)));
        }
      },
    );
  }

  void _stopAttentionReminders({required bool clearState}) {
    _remindersKey = '';
    _remindersSubscription?.cancel();
    _remindersSubscription = null;
    if (clearState && !isClosed) {
      emit(
        state.copyWith(
          reminders: const <AttentionReminder>[],
          clearReminderMessage: true,
          clearedReminderIds: const <String>{},
        ),
      );
    }
  }

  Future<void> markAsRead({
    required String companyId,
    required CrmNotification notification,
  }) async {
    if (notification.isRead) {
      return;
    }
    _locallyReadNotificationIds.add(notification.id);
    emit(
      state.copyWith(
        markingNotificationId: notification.id,
        notifications: _markNotificationReadInList(
          state.notifications,
          notification.id,
        ),
        unreadCount: _decrementUnreadCount(state.unreadCount),
        clearMessage: true,
      ),
    );
    try {
      await _markNotificationReadUseCase(
        companyId: companyId,
        notificationId: notification.id,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            notifications: _markNotificationReadInList(
              state.notifications,
              notification.id,
            ),
            clearMarkingNotificationId: true,
            clearMessage: true,
          ),
        );
      }
    } on NotificationException catch (error) {
      _locallyReadNotificationIds.remove(notification.id);
      if (!isClosed) {
        emit(
          state.copyWith(
            message: error.message,
            clearMarkingNotificationId: true,
          ),
        );
      }
    } catch (_) {
      _locallyReadNotificationIds.remove(notification.id);
      if (!isClosed) {
        emit(
          state.copyWith(
            message: AppErrorMessages.unknown,
            clearMarkingNotificationId: true,
          ),
        );
      }
    }
  }

  Future<void> clearNotification({
    required String companyId,
    required CrmNotification notification,
  }) async {
    _locallyReadNotificationIds.add(notification.id);
    final clearedIds = <String>{...state.clearedNotificationIds, notification.id};
    emit(
      state.copyWith(
        notifications: state.notifications
            .where((item) => item.id != notification.id)
            .toList(),
        clearedNotificationIds: clearedIds,
        unreadCount: notification.isRead
            ? state.unreadCount
            : _decrementUnreadCount(state.unreadCount),
        clearMessage: true,
      ),
    );

    try {
      await _dismissNotificationUseCase(
        companyId: companyId,
        notificationId: notification.id,
      );
    } on NotificationException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(message: error.message));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(message: AppErrorMessages.unknown));
      }
    }
  }

  Future<void> markResolved({
    required String companyId,
    required CrmNotification notification,
  }) async {
    if (notification.isResolved || notification.isDismissed) {
      return;
    }
    emit(state.copyWith(markingNotificationId: notification.id));
    try {
      await _markNotificationResolvedUseCase(
        companyId: companyId,
        notificationId: notification.id,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            notifications: _markNotificationResolvedInList(
              state.notifications,
              notification.id,
            ),
            unreadCount: notification.isRead
                ? state.unreadCount
                : _decrementUnreadCount(state.unreadCount),
            clearMarkingNotificationId: true,
            clearMessage: true,
          ),
        );
      }
    } on NotificationException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            message: error.message,
            clearMarkingNotificationId: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            message: AppErrorMessages.unknown,
            clearMarkingNotificationId: true,
          ),
        );
      }
    }
  }

  void clearAttentionReminder(String reminderId) {
    final clearedIds = <String>{...state.clearedReminderIds, reminderId};
    emit(
      state.copyWith(
        reminders: state.reminders
            .where((reminder) => reminder.id != reminderId)
            .toList(),
        clearedReminderIds: clearedIds,
        clearReminderMessage: true,
      ),
    );
  }

  Future<void> markAllRead({
    required String companyId,
    required String currentUserId,
  }) async {
    if (state.markingAllRead || !state.hasUnreadNotifications) {
      return;
    }
    final unreadIds = state.notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toSet();
    _locallyReadNotificationIds.addAll(unreadIds);
    _suppressUnreadCountUntil = DateTime.now().add(const Duration(minutes: 5));
    emit(
      state.copyWith(
        markingAllRead: true,
        notifications: _markAllNotificationsReadInList(state.notifications),
        unreadCount: 0,
        clearMessage: true,
      ),
    );
    try {
      await _markAllNotificationsReadUseCase(
        companyId: companyId,
        recipientUid: currentUserId,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            notifications: _markAllNotificationsReadInList(
              state.notifications,
            ),
            unreadCount: 0,
            markingAllRead: false,
          ),
        );
      }
    } on NotificationException catch (error) {
      _locallyReadNotificationIds.removeAll(unreadIds);
      _suppressUnreadCountUntil = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            markingAllRead: false,
            message: error.message,
          ),
        );
      }
    } catch (_) {
      _locallyReadNotificationIds.removeAll(unreadIds);
      _suppressUnreadCountUntil = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            markingAllRead: false,
            message: AppErrorMessages.unknown,
          ),
        );
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is NotificationException) {
      return error.message;
    }
    return AppErrorMessages.unknown;
  }

  List<CrmNotification> _markNotificationReadInList(
    List<CrmNotification> notifications,
    String notificationId,
  ) {
    final now = DateTime.now();
    return notifications
        .map(
          (notification) => notification.id == notificationId
              ? notification.copyWith(isRead: true, readAt: now)
              : notification,
        )
        .toList();
  }


  List<CrmNotification> _markNotificationResolvedInList(
    List<CrmNotification> notifications,
    String notificationId,
  ) {
    final now = DateTime.now();
    return notifications
        .map(
          (notification) => notification.id == notificationId
              ? notification.copyWith(
                  isRead: true,
                  readAt: now,
                  actionState: CrmNotificationActionState.resolved,
                  resolvedAt: now,
                )
              : notification,
        )
        .toList();
  }

  List<CrmNotification> _markAllNotificationsReadInList(
    List<CrmNotification> notifications,
  ) {
    final now = DateTime.now();
    return notifications
        .map((notification) => notification.copyWith(isRead: true, readAt: now))
        .toList();
  }


  List<CrmNotification> _applyLocalReadOverrides(
    List<CrmNotification> notifications,
  ) {
    if (_locallyReadNotificationIds.isEmpty) {
      return notifications;
    }
    final now = DateTime.now();
    return notifications
        .map(
          (notification) => _locallyReadNotificationIds.contains(notification.id)
              ? notification.copyWith(
                  isRead: true,
                  readAt: notification.readAt ?? now,
                )
              : notification,
        )
        .toList();
  }

  List<CrmNotification> _filterClearedNotifications(
    List<CrmNotification> notifications,
  ) {
    if (state.clearedNotificationIds.isEmpty) {
      return notifications;
    }
    return notifications
        .where((notification) =>
            !state.clearedNotificationIds.contains(notification.id))
        .toList();
  }

  List<AttentionReminder> _filterClearedReminders(
    List<AttentionReminder> reminders,
  ) {
    if (state.clearedReminderIds.isEmpty) {
      return reminders;
    }
    return reminders
        .where((reminder) => !state.clearedReminderIds.contains(reminder.id))
        .toList();
  }

  int _decrementUnreadCount(int unreadCount) {
    return unreadCount <= 0 ? 0 : unreadCount - 1;
  }

  @override
  Future<void> close() {
    _attentionRequests.clear();
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _remindersSubscription?.cancel();
    return super.close();
  }
}

class _AttentionWatchRequest {
  const _AttentionWatchRequest({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    required this.managerTeamId,
    required this.limit,
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String? managerTeamId;
  final int limit;
}
