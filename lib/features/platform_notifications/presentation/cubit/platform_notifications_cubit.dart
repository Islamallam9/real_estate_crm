import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/platform_notification.dart';
import '../../domain/usecases/mark_all_platform_notifications_read_usecase.dart';
import '../../domain/usecases/mark_platform_notification_read_usecase.dart';
import '../../domain/usecases/watch_platform_notifications_usecase.dart';
import '../../domain/usecases/watch_platform_unread_notifications_count_usecase.dart';
import 'platform_notifications_state.dart';

class PlatformNotificationsCubit extends Cubit<PlatformNotificationsState> {
  PlatformNotificationsCubit({
    required WatchPlatformNotificationsUseCase watchNotificationsUseCase,
    required WatchPlatformUnreadNotificationsCountUseCase watchUnreadCountUseCase,
    required MarkPlatformNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllPlatformNotificationsReadUseCase markAllReadUseCase,
  })  : _watchNotificationsUseCase = watchNotificationsUseCase,
        _watchUnreadCountUseCase = watchUnreadCountUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllReadUseCase = markAllReadUseCase,
        super(const PlatformNotificationsState.initial());

  final WatchPlatformNotificationsUseCase _watchNotificationsUseCase;
  final WatchPlatformUnreadNotificationsCountUseCase _watchUnreadCountUseCase;
  final MarkPlatformNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllPlatformNotificationsReadUseCase _markAllReadUseCase;

  StreamSubscription<List<PlatformNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadSubscription;
  bool _watchingNotifications = false;
  bool _watchingUnreadCount = false;

  void watch() {
    watchUnreadCount();
    watchNotifications();
  }

  void watchUnreadCount() {
    if (_watchingUnreadCount) {
      return;
    }
    _watchingUnreadCount = true;
    _unreadSubscription = _watchUnreadCountUseCase().listen(
      (count) {
        if (!isClosed) {
          emit(state.copyWith(unreadCount: count, clearMessage: true));
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(state.copyWith(message: error.toString()));
        }
      },
    );
  }

  void watchNotifications() {
    if (_watchingNotifications) {
      return;
    }
    _watchingNotifications = true;
    emit(state.copyWith(status: PlatformNotificationsStatus.loading));
    _notificationsSubscription = _watchNotificationsUseCase().listen(
      (notifications) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PlatformNotificationsStatus.ready,
              notifications: notifications,
              clearMessage: true,
            ),
          );
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PlatformNotificationsStatus.failure,
              message: error.toString(),
            ),
          );
        }
      },
    );
  }

  void setFilter(PlatformNotificationFilter filter) {
    emit(state.copyWith(filter: filter, clearMessage: true));
  }

  Future<void> markRead({
    required PlatformNotification notification,
    required bool isRead,
  }) async {
    emit(
      state.copyWith(
        markingNotificationId: notification.id,
        clearMessage: true,
      ),
    );
    try {
      await _markNotificationReadUseCase(
        notificationId: notification.id,
        isRead: isRead,
      );
      if (!isClosed) {
        emit(state.copyWith(clearMarkingNotificationId: true));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            message: error.toString(),
            clearMarkingNotificationId: true,
          ),
        );
      }
    }
  }

  Future<void> markAllRead() async {
    if (state.markingAllRead || state.unreadCount == 0) {
      return;
    }
    emit(state.copyWith(markingAllRead: true, clearMessage: true));
    try {
      await _markAllReadUseCase();
      if (!isClosed) {
        emit(state.copyWith(markingAllRead: false));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            markingAllRead: false,
            message: error.toString(),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _unreadSubscription?.cancel();
    return super.close();
  }
}
