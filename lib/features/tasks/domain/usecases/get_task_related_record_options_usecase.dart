import '../entities/crm_task.dart';
import '../entities/task_related_record_option.dart';
import '../repositories/task_repository.dart';

class GetTaskRelatedRecordOptionsUseCase {
  const GetTaskRelatedRecordOptionsUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<TaskRelatedRecordOption>> call({
    required String companyId,
    required TaskRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  }) {
    return _repository.getRelatedRecordOptions(
      companyId: companyId,
      type: type,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      limit: limit,
    );
  }
}
