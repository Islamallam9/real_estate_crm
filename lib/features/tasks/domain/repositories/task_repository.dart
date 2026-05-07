import '../entities/crm_task.dart';
import '../entities/task_related_record_option.dart';

abstract interface class TaskRepository {
  Future<CrmTask> createTask({
    required String companyId,
    required CrmTask task,
  });

  Future<CrmTask> updateTask({
    required String companyId,
    required CrmTask task,
  });

  Stream<CrmTask?> watchTask({
    required String companyId,
    required String taskId,
  });

  Stream<List<CrmTask>> watchTasks({
    required String companyId,
    String? assignedTo,
    int limit,
  });

  Future<List<TaskRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required TaskRelatedType type,
    String? assignedTo,
    int limit,
  });
}
