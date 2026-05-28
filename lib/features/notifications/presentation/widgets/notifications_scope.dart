import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/notifications_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/usecases/dismiss_notification_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_notification_resolved_usecase.dart';
import '../../domain/usecases/watch_attention_reminders_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';
import '../../domain/usecases/watch_unread_notifications_count_usecase.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsScope extends StatelessWidget {
  const NotificationsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = NotificationRepositoryImpl(
      remoteDataSource: FirestoreNotificationsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => NotificationsCubit(
        watchNotificationsUseCase: WatchNotificationsUseCase(repository),
        watchUnreadCountUseCase:
            WatchUnreadNotificationsCountUseCase(repository),
        watchAttentionRemindersUseCase:
            WatchAttentionRemindersUseCase(repository),
        markNotificationReadUseCase: MarkNotificationReadUseCase(repository),
        markNotificationResolvedUseCase:
            MarkNotificationResolvedUseCase(repository),
        dismissNotificationUseCase: DismissNotificationUseCase(repository),
        markAllNotificationsReadUseCase:
            MarkAllNotificationsReadUseCase(repository),
      ),
      child: child,
    );
  }
}
