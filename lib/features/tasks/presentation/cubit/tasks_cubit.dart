import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/stats/module_kpi_counts_data_source.dart';
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
  final FirestoreModuleKpiCountsDataSource _countsDataSource =
      FirestoreModuleKpiCountsDataSource();

  StreamSubscription<List<CrmTask>>? _tasksSubscription;
  StreamSubscription<CrmTask?>? _taskSubscription;
  String? _watchedCompanyId;
  String? _watchedAssignedTo;
  String? _watchedManagerId;
  String? _watchedTeamId;
  static const int _defaultPageLimit = 15;
  static const int _pageIncrement = 15;
  static const int _filterScanLimit = 500;
  static const List<String> _kpiCountKeys = <String>[
    'total',
    'overdue',
    'today',
    'upcoming',
    'completed',
    'cancelled',
  ];
  static const int _dashboardWatchLimit = 1000;
  final InitialLoadTimeout _tasksInitialLoadTimeout = InitialLoadTimeout();
  final InitialLoadTimeout _taskInitialLoadTimeout = InitialLoadTimeout();

  void watchTasks({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int? limit,
    bool resetPage = true,
    bool usePagination = true,
  }) {
    _watchedCompanyId = companyId;
    _watchedAssignedTo = assignedTo;
    _watchedManagerId = managerId;
    _watchedTeamId = teamId;
    final effectiveAssignedTo = _effectiveAssignedToScope();
    final hasLocalFilters = _hasLocalTaskFilters();
    final pageLimit = usePagination
        ? (resetPage ? _defaultPageLimit : limit ?? state.pageLimit)
        : state.pageLimit;
    final queryLimit = usePagination
        ? (hasLocalFilters ? _filterScanLimit : pageLimit)
        : _dashboardWatchLimit;
    emit(
      state.copyWith(
        status: resetPage || state.tasks.isEmpty
            ? TasksStatus.loading
            : TasksStatus.loadingMore,
        pageLimit: pageLimit,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    if (resetPage || !state.kpiCounts.hasAll(_kpiCountKeys)) {
      _refreshKpiCounts();
    }
    _tasksSubscription?.cancel();
    _tasksInitialLoadTimeout.start(() {
      if (isClosed ||
          (state.status != TasksStatus.loading &&
              state.status != TasksStatus.loadingMore) ||
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
      assignedTo: effectiveAssignedTo,
      managerId: managerId,
      teamId: teamId,
      limit: queryLimit,
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
            pageLimit: pageLimit,
            clearMessage: true,
          ),
        );
        unawaited(_refreshKpiCounts());
        _debugCheckKpiInvariant();
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



  Future<void> _refreshKpiCounts() async {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return;
    }
    final counts = await _countsDataSource.taskCounts(
      companyId: companyId,
      assignedTo: _effectiveAssignedToScope(),
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
    );
    if (!isClosed && _watchedCompanyId == companyId) {
      emit(state.copyWith(kpiCounts: counts));
      _debugCheckKpiInvariant();
    }
  }

  void _debugCheckKpiInvariant() {
    debugCheckModuleKpiInvariant(
      module: 'tasks',
      loadedRows: state.tasks.length,
      totalCount: state.kpiCounts.valueOrNull('total'),
      hasLocalFilters: _hasLocalTaskFilters(),
      scopeLabel: 'active',
    );
  }

  void loadMoreTasks() {
    final companyId = _watchedCompanyId;
    if (companyId == null ||
        companyId.isEmpty ||
        state.status == TasksStatus.loading ||
        state.status == TasksStatus.loadingMore) {
      return;
    }

    final nextLimit = state.pageLimit + _pageIncrement;
    if (state.filteredTasks.length > state.pageLimit) {
      emit(state.copyWith(pageLimit: nextLimit));
      _debugCheckKpiInvariant();
      return;
    }
    if (!state.canLoadMore) {
      return;
    }

    watchTasks(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      limit: nextLimit,
      resetPage: false,
    );
  }

  void _reloadCurrentTaskScopeAfterFilterChange() {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return;
    }
    watchTasks(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      resetPage: true,
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
        pageLimit: _defaultPageLimit,
        filteredTasks: _applyFilters(state.tasks, searchQuery: query),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
  }

  void setStatusFilter(TaskStatus? status) {
    emit(
      state.copyWith(
        statusFilter: status,
        pageLimit: _defaultPageLimit,
        clearStatusFilter: status == null,
        filteredTasks: _applyFilters(
          state.tasks,
          statusFilter: status,
          overrideStatusFilter: true,
        ),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
  }

  void setPriorityFilter(TaskPriority? priority) {
    emit(
      state.copyWith(
        priorityFilter: priority,
        pageLimit: _defaultPageLimit,
        clearPriorityFilter: priority == null,
        filteredTasks: _applyFilters(
          state.tasks,
          priorityFilter: priority,
          overridePriorityFilter: true,
        ),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
  }

  void setDueDateFilter(TaskDueDateFilter? dueDateFilter) {
    emit(
      state.copyWith(
        dueDateFilter: dueDateFilter,
        pageLimit: _defaultPageLimit,
        clearDueDateFilter: dueDateFilter == null,
        filteredTasks: _applyFilters(
          state.tasks,
          dueDateFilter: dueDateFilter,
          overrideDueDateFilter: true,
        ),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
  }


  void applyKpiFilter({
    TaskStatus? statusFilter,
    TaskDueDateFilter? dueDateFilter,
  }) {
    emit(
      state.copyWith(
        searchQuery: '',
        pageLimit: _defaultPageLimit,
        statusFilter: statusFilter,
        clearStatusFilter: statusFilter == null,
        clearPriorityFilter: true,
        dueDateFilter: dueDateFilter,
        clearDueDateFilter: dueDateFilter == null,
        filteredTasks: _applyFilters(
          state.tasks,
          searchQuery: '',
          statusFilter: statusFilter,
          priorityFilter: null,
          dueDateFilter: dueDateFilter,
          overrideStatusFilter: true,
          overridePriorityFilter: true,
          overrideDueDateFilter: true,
        ),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        pageLimit: _defaultPageLimit,
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
    _reloadCurrentTaskScopeAfterFilterChange();
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        pageLimit: _defaultPageLimit,
        filteredTasks: _applyFilters(state.tasks, assignedToFilter: assignedTo),
      ),
    );
    _reloadCurrentTaskScopeAfterFilterChange();
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
      unawaited(_refreshKpiCounts());
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
      unawaited(_refreshKpiCounts());
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


  String? _effectiveAssignedToScope() {
    final baseAssignedTo = _watchedAssignedTo?.trim() ?? '';
    if (baseAssignedTo.isNotEmpty) {
      return baseAssignedTo;
    }
    if ((_watchedManagerId?.trim().isNotEmpty ?? false) ||
        (_watchedTeamId?.trim().isNotEmpty ?? false)) {
      return null;
    }
    final selectedAssignedTo = state.assignedToFilter.trim();
    return selectedAssignedTo.isEmpty ? null : selectedAssignedTo;
  }

  bool _hasLocalTaskFilters() {
    return state.searchQuery.trim().isNotEmpty ||
        state.statusFilter != null ||
        state.priorityFilter != null ||
        state.dueDateFilter != null ||
        state.assignedToFilter.trim().isNotEmpty;
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

    filtered.sort(_compareTasksByCreatedAtDesc);
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

  int _compareTasksByCreatedAtDesc(CrmTask a, CrmTask b) {
    final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return b.id.compareTo(a.id);
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
    _refreshKpiCounts();
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
