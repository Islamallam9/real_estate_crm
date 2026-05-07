import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/tasks_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/get_task_related_record_options_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/watch_task_usecase.dart';
import '../../domain/usecases/watch_tasks_usecase.dart';
import '../cubit/tasks_cubit.dart';

class TasksScope extends StatelessWidget {
  const TasksScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = TaskRepositoryImpl(
      remoteDataSource: FirestoreTasksRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => TasksCubit(
        watchTasksUseCase: WatchTasksUseCase(repository),
        watchTaskUseCase: WatchTaskUseCase(repository),
        createTaskUseCase: CreateTaskUseCase(repository),
        updateTaskUseCase: UpdateTaskUseCase(repository),
        getRelatedRecordOptionsUseCase:
            GetTaskRelatedRecordOptionsUseCase(repository),
      ),
      child: child,
    );
  }
}
