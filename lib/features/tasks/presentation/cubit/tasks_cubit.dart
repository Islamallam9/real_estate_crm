import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/errors/task_exception.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/get_task_related_record_options_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/watch_task_usecase.dart';
import '../../domain/usecases/watch_tasks_usecase.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required WatchTasksUseCase watchTasksUseCase,
    required WatchTaskUseCase watchTaskUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required GetTaskRelatedRecordOptionsUseCase getRelatedRecordOptionsUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchTasksUseCase = watchTasksUseCase,
       _watchTaskUseCase = watchTaskUseCase,
       _createTaskUseCase = createTaskUseCase,
       _updateTaskUseCase = updateTaskUseCase,
       _getRelatedRecordOptionsUseCase = getRelatedRecordOptionsUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
       super(const TasksState.initial());

  final WatchTasksUseCase _watchTasksUseCase;
  final WatchTaskUseCase _watchTaskUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final GetTaskRelatedRecordOptionsUseCase _getRelatedRecordOptionsUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;

  StreamSubscription<List<CrmTask>>? _tasksSubscription;
  StreamSubscription<CrmTask?>? _taskSubscription;
  final InitialLoadTimeout _tasksInitialLoadTimeout = InitialLoadTimeout();
  final InitialLoadTimeout _taskInitialLoadTimeout = InitialLoadTimeout();

  void watchTasks({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    emit(
      state.copyWith(
        status: TasksStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _tasksSubscription?.cancel();
    _tasksInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != TasksStatus.loading ||
          state.tasks.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _tasksSubscription = _watchTasksUseCase(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    ).listen(
      (tasks) {
        if (isClosed) {
          return;
        }
        _tasksInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: tasks.isEmpty ? TasksStatus.empty : TasksStatus.loaded,
            tasks: tasks,
            filteredTasks: _applyFilters(tasks),
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _tasksInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: TasksStatus.failure,
            message: _taskErrorMessage(error, AppErrorMessages.unknown),
          ),
        );
      },
    );
  }

  void watchTask({required String companyId, required String taskId}) {
    emit(
      state.copyWith(
        status: TasksStatus.loading,
        clearMessage: true,
        clearLastAction: true,
        clearSelectedTask: true,
      ),
    );
    _taskSubscription?.cancel();
    _taskInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != TasksStatus.loading ||
          state.selectedTask != null) {
        return;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _taskSubscription = _watchTaskUseCase(
      companyId: companyId,
      taskId: taskId,
    ).listen(
      (task) {
        if (isClosed) {
          return;
        }
        _taskInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: task == null ? TasksStatus.empty : TasksStatus.loaded,
            selectedTask: task,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _taskInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: TasksStatus.failure,
            message: _taskErrorMessage(error, AppErrorMessages.unknown),
          ),
        );
      },
    );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredTasks: _applyFilters(state.tasks, searchQuery: query),
      ),
    );
  }

  void setStatusFilter(TaskStatus? status) {
    emit(
      state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        filteredTasks: _applyFilters(
          state.tasks,
          statusFilter: status,
          overrideStatusFilter: true,
        ),
      ),
    );
  }

  void setPriorityFilter(TaskPriority? priority) {
    emit(
      state.copyWith(
        priorityFilter: priority,
        clearPriorityFilter: priority == null,
        filteredTasks: _applyFilters(
          state.tasks,
          priorityFilter: priority,
          overridePriorityFilter: true,
        ),
      ),
    );
  }

  void setDueDateFilter(TaskDueDateFilter? dueDateFilter) {
    emit(
      state.copyWith(
        dueDateFilter: dueDateFilter,
        clearDueDateFilter: dueDateFilter == null,
        filteredTasks: _applyFilters(
          state.tasks,
          dueDateFilter: dueDateFilter,
          overrideDueDateFilter: true,
        ),
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        clearStatusFilter: true,
        clearPriorityFilter: true,
        clearDueDateFilter: true,
        clearAssignedToFilter: true,
        filteredTasks: _applyFilters(
          state.tasks,
          searchQuery: '',
          statusFilter: null,
          priorityFilter: null,
          dueDateFilter: null,
          assignedToFilter: '',
          overrideStatusFilter: true,
          overridePriorityFilter: true,
          overrideDueDateFilter: true,
        ),
      ),
    );
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        filteredTasks: _applyFilters(state.tasks, assignedToFilter: assignedTo),
      ),
    );
  }

  Future<bool> createTask({
    required String companyId,
    required CrmTask task,
  }) async {
    emit(
      state.copyWith(
        status: TasksStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final createdTask = await _createTaskUseCase(
        companyId: companyId,
        task: task,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: createdTask.createdBy,
          action: AuditLogAction.create,
          recordId: createdTask.id,
          recordTitle: _taskTitle(createdTask),
          recordSubtitle: _taskSubtitle(createdTask),
          metadata: {
            'status': _taskStatusValue(createdTask.status),
            'assignedTo': createdTask.assignedTo,
            'assignedToName': createdTask.assignedToName,
            'teamId': createdTask.teamId,
            'teamName': createdTask.teamName,
            'managerId': createdTask.managerId,
            'managerName': createdTask.managerName,
            'relatedType': createdTask.relatedType.name,
          },
        ),
      );
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TasksStatus.saved,
          clearMessage: true,
          lastAction: TasksAction.createTask,
        ),
      );
      return true;
    } on TaskException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: error.message,
          lastAction: TasksAction.createTask,
        ),
      );
      return false;
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: TasksAction.createTask,
        ),
      );
      return false;
    }
  }

  Future<bool> updateTask({
    required String companyId,
    required CrmTask task,
    TasksAction action = TasksAction.updateTask,
  }) async {
    emit(
      state.copyWith(
        status: TasksStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final previousTask = _taskById(task.id);
      final updatedTask = await _updateTaskUseCase(
        companyId: companyId,
        task: task,
      );
      final auditAction = switch (action) {
        TasksAction.markCompleted => AuditLogAction.complete,
        TasksAction.cancelTask => AuditLogAction.cancel,
        _ => AuditLogAction.update,
      };
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedTask.updatedBy,
          action: auditAction,
          recordId: updatedTask.id,
          recordTitle: _taskTitle(updatedTask),
          recordSubtitle: _taskSubtitle(updatedTask),
          metadata: {
            if (previousTask != null) ...{
              'previousStatus': _taskStatusValue(previousTask.status),
              'newStatus': _taskStatusValue(updatedTask.status),
            },
            'assignedTo': updatedTask.assignedTo,
            'assignedToName': updatedTask.assignedToName,
            'teamId': updatedTask.teamId,
            'teamName': updatedTask.teamName,
            'managerId': updatedTask.managerId,
            'managerName': updatedTask.managerName,
            'relatedType': updatedTask.relatedType.name,
          },
        ),
      );
      if (isClosed) {
        return false;
      }
      final updatedTasks = _replaceTaskInCurrentList(updatedTask);
      emit(
        state.copyWith(
          status: TasksStatus.saved,
          tasks: updatedTasks,
          filteredTasks: _applyFilters(
            updatedTasks,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dueDateFilter: state.dueDateFilter,
            assignedToFilter: state.assignedToFilter,
          ),
          selectedTask: state.selectedTask?.id == updatedTask.id
              ? updatedTask
              : state.selectedTask,
          clearMessage: true,
          lastAction: action,
        ),
      );
      return true;
    } on TaskException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: error.message,
          lastAction: action,
        ),
      );
      return false;
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: action,
        ),
      );
      return false;
    }
  }

  Future<bool> markCompleted({
    required String companyId,
    required CrmTask task,
    required String updatedBy,
  }) {
    return updateTask(
      companyId: companyId,
      task: task.copyWith(status: TaskStatus.completed, updatedBy: updatedBy),
      action: TasksAction.markCompleted,
    );
  }

  Future<bool> cancelTask({
    required String companyId,
    required CrmTask task,
    required String updatedBy,
  }) {
    return updateTask(
      companyId: companyId,
      task: task.copyWith(status: TaskStatus.cancelled, updatedBy: updatedBy),
      action: TasksAction.cancelTask,
    );
  }

  Future<void> loadRelatedRecordOptions({
    required String companyId,
    required TaskRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) async {
    if (type == TaskRelatedType.general) {
      emit(
        state.copyWith(
          clearRelatedRecords: true,
          clearRelatedRecordsMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        relatedRecordsStatus: TaskRelatedRecordsStatus.loading,
        relatedRecordsType: type,
        relatedRecordOptions: const [],
        clearRelatedRecordsMessage: true,
      ),
    );
    try {
      final options = await _getRelatedRecordOptionsUseCase(
        companyId: companyId,
        type: type,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: options.isEmpty
              ? TaskRelatedRecordsStatus.empty
              : TaskRelatedRecordsStatus.loaded,
          relatedRecordsType: type,
          relatedRecordOptions: options,
          clearRelatedRecordsMessage: true,
        ),
      );
    } on TaskException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: TaskRelatedRecordsStatus.failure,
          relatedRecordsType: type,
          relatedRecordOptions: const [],
          relatedRecordsMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: TaskRelatedRecordsStatus.failure,
          relatedRecordsType: type,
          relatedRecordOptions: const [],
          relatedRecordsMessage: AppErrorMessages.unknown,
        ),
      );
    }
  }

  void clearRelatedRecordOptions() {
    emit(
      state.copyWith(
        clearRelatedRecords: true,
        clearRelatedRecordsMessage: true,
      ),
    );
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }


  List<CrmTask> _replaceTaskInCurrentList(CrmTask updated) {
    final index = state.tasks.indexWhere((task) => task.id == updated.id);
    if (index < 0) {
      return state.tasks;
    }
    final next = List<CrmTask>.of(state.tasks);
    next[index] = updated;
    return next;
  }

  List<CrmTask> _applyFilters(
    List<CrmTask> tasks, {
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    TaskDueDateFilter? dueDateFilter,
    String? assignedToFilter,
    bool overrideStatusFilter = false,
    bool overridePriorityFilter = false,
    bool overrideDueDateFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStatus = overrideStatusFilter
        ? statusFilter
        : statusFilter ?? state.statusFilter;
    final selectedPriority = overridePriorityFilter
        ? priorityFilter
        : priorityFilter ?? state.priorityFilter;
    final selectedDueDateFilter = overrideDueDateFilter
        ? dueDateFilter
        : dueDateFilter ?? state.dueDateFilter;
    final selectedAssignedTo = (assignedToFilter ?? state.assignedToFilter).trim();
    final today = _dateOnly(DateTime.now());

    final filtered = tasks.where((task) {
      final assigneeLabel = _assigneeSearchText(task);
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.relatedTitle.toLowerCase().contains(query) ||
          task.relatedSubtitle.toLowerCase().contains(query) ||
          assigneeLabel.contains(query);
      final matchesStatus = selectedStatus == null || task.status == selectedStatus;
      final matchesPriority =
          selectedPriority == null || task.priority == selectedPriority;
      final matchesDueDate =
          selectedDueDateFilter == null ||
          _matchesDueDateFilter(task, selectedDueDateFilter, today);
      final matchesAssignedTo =
          selectedAssignedTo.isEmpty || task.assignedTo == selectedAssignedTo;
      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesDueDate &&
          matchesAssignedTo;
    }).toList();

    filtered.sort((a, b) => _compareTasksByUrgency(a, b, today));
    return filtered;
  }

  bool _matchesDueDateFilter(
    CrmTask task,
    TaskDueDateFilter filter,
    DateTime today,
  ) {
    switch (filter) {
      case TaskDueDateFilter.overdue:
        return DashboardTruthRules.isOverdueTask(task, today);
      case TaskDueDateFilter.today:
        return DashboardTruthRules.isDueTodayTask(task, today);
      case TaskDueDateFilter.upcoming:
        return DashboardTruthRules.isUpcomingTask(task, today);
    }
  }

  int _compareTasksByUrgency(CrmTask a, CrmTask b, DateTime today) {
    final groupCompare = _urgencyGroup(a, today).compareTo(
      _urgencyGroup(b, today),
    );
    if (groupCompare != 0) {
      return groupCompare;
    }
    final aDate = a.dueDate ?? DateTime(9999);
    final bDate = b.dueDate ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }

  int _urgencyGroup(CrmTask task, DateTime today) {
    final dueDate = task.dueDate;
    if (!_isIncomplete(task)) {
      return 3;
    }
    if (dueDate == null) {
      return 2;
    }
    final dueDay = _dateOnly(dueDate);
    if (dueDay.isBefore(today)) {
      return 0;
    }
    if (dueDay == today) {
      return 1;
    }
    return 2;
  }

  bool _isIncomplete(CrmTask task) {
    return task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _assigneeSearchText(CrmTask task) {
    return '${task.assignedToName} ${task.assignedToEmail}'.toLowerCase();
  }

  String _taskErrorMessage(Object error, String fallback) {
    if (error is TaskException) {
      return error.message;
    }
    return fallback;
  }

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: '',
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.tasks,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block task workflows.
    }
  }

  CrmTask? _taskById(String taskId) {
    if (state.selectedTask?.id == taskId) {
      return state.selectedTask;
    }
    for (final task in state.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<void> close() {
    _tasksInitialLoadTimeout.cancel();
    _taskInitialLoadTimeout.cancel();
    _tasksSubscription?.cancel();
    _taskSubscription?.cancel();
    return super.close();
  }
}

String _taskTitle(CrmTask task) {
  final title = task.title.trim();
  return title.isEmpty ? 'Task' : title;
}

String _taskSubtitle(CrmTask task) {
  final relatedTitle = task.relatedTitle.trim();
  if (relatedTitle.isNotEmpty) {
    return relatedTitle;
  }
  final dueDate = task.dueDate;
  if (dueDate != null) {
    return _formatAuditDate(dueDate);
  }
  return task.assignedToName.trim();
}

String _taskStatusValue(TaskStatus status) {
  return switch (status) {
    TaskStatus.pending => 'pending',
    TaskStatus.inProgress => 'inProgress',
    TaskStatus.completed => 'completed',
    TaskStatus.cancelled => 'cancelled',
  };
}

String _formatAuditDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
