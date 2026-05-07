import '../entities/crm_task.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<CrmTask> call({
    required String companyId,
    required CrmTask task,
  }) {
    return _repository.updateTask(companyId: companyId, task: task);
  }
}
