import '../entities/crm_task.dart';
import '../repositories/task_repository.dart';

class WatchTasksUseCase {
  const WatchTasksUseCase(this._repository);

  final TaskRepository _repository;

  Stream<List<CrmTask>> call({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 40,
  }) {
    return _repository.watchTasks(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      limit: limit,
    );
  }
}
