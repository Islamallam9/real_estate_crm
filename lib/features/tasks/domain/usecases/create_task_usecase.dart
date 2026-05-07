import '../entities/crm_task.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<CrmTask> call({
    required String companyId,
    required CrmTask task,
  }) {
    return _repository.createTask(companyId: companyId, task: task);
  }
}
