import '../../domain/entities/crm_task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/tasks_remote_data_source.dart';
import '../models/crm_task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl({required TasksRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TasksRemoteDataSource _remoteDataSource;

  @override
  Future<CrmTask> createTask({
    required String companyId,
    required CrmTask task,
  }) {
    return _remoteDataSource.createTask(
      companyId: companyId,
      task: CrmTaskModel.fromEntity(task),
    );
  }

  @override
  Stream<List<CrmTask>> watchTasks({
    required String companyId,
    String? assignedTo,
    int limit = 40,
  }) {
    return _remoteDataSource.watchTasks(
      companyId: companyId,
      assignedTo: assignedTo,
      limit: limit,
    );
  }
}
