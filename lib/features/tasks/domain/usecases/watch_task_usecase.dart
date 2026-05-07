import '../entities/crm_task.dart';
import '../repositories/task_repository.dart';

class WatchTaskUseCase {
  const WatchTaskUseCase(this._repository);

  final TaskRepository _repository;

  Stream<CrmTask?> call({
    required String companyId,
    required String taskId,
  }) {
    return _repository.watchTask(companyId: companyId, taskId: taskId);
  }
}
