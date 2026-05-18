import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/errors/notification_exception.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
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
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
  })  : _watchNotificationsUseCase = watchNotificationsUseCase,
        _watchUnreadCountUseCase = watchUnreadCountUseCase,
        _watchAttentionRemindersUseCase = watchAttentionRemindersUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        super(const NotificationsState.initial());

  final WatchNotificationsUseCase _watchNotificationsUseCase;
  final WatchUnreadNotificationsCountUseCase _watchUnreadCountUseCase;
  final WatchAttentionRemindersUseCase _watchAttentionRemindersUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;

  StreamSubscription<List<CrmNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<List<AttentionReminder>>? _remindersSubscription;
  String _watchKey = '';

  void watch({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int notificationsLimit = notificationDropdownLimit,
    int remindersLimit = 60,
  }) {
    final key =
        '$companyId:$currentUserId:${role.name}:${managerTeamId ?? ''}:$notificationsLimit:$remindersLimit';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _remindersSubscription?.cancel();
    emit(
      state.copyWith(
        status: NotificationsStatus.loading,
        clearMessage: true,
        clearReminderMessage: true,
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
            notifications: notifications,
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

    _unreadCountSubscription = _watchUnreadCountUseCase(
      companyId: companyId,
      recipientUid: currentUserId,
    ).listen(
      (count) {
        if (!isClosed) {
          emit(state.copyWith(unreadCount: count, clearMessage: true));
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(state.copyWith(message: _errorMessage(error)));
        }
      },
    );

    _remindersSubscription = _watchAttentionRemindersUseCase(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: remindersLimit,
    ).listen(
      (reminders) {
        if (!isClosed) {
          emit(
            state.copyWith(
              reminders: reminders,
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

  Future<void> markAsRead({
    required String companyId,
    required CrmNotification notification,
  }) async {
    if (notification.isRead) {
      return;
    }
    emit(state.copyWith(markingNotificationId: notification.id));
    try {
      await _markNotificationReadUseCase(
        companyId: companyId,
        notificationId: notification.id,
      );
      if (!isClosed) {
        emit(state.copyWith(clearMarkingNotificationId: true));
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

  Future<void> markAllRead({
    required String companyId,
    required String currentUserId,
  }) async {
    if (state.markingAllRead || state.unreadCount == 0) {
      return;
    }
    emit(state.copyWith(markingAllRead: true, clearMessage: true));
    try {
      await _markAllNotificationsReadUseCase(
        companyId: companyId,
        recipientUid: currentUserId,
      );
      if (!isClosed) {
        emit(state.copyWith(markingAllRead: false));
      }
    } on NotificationException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            markingAllRead: false,
            message: error.message,
          ),
        );
      }
    } catch (_) {
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

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _remindersSubscription?.cancel();
    return super.close();
  }
}
