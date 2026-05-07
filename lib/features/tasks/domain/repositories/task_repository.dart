import '../entities/crm_task.dart';

abstract interface class TaskRepository {
  Future<CrmTask> createTask({
    required String companyId,
    required CrmTask task,
  });

  Stream<List<CrmTask>> watchTasks({
    required String companyId,
    String? assignedTo,
    int limit,
  });
}
