import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/errors/task_exception.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/watch_tasks_usecase.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required WatchTasksUseCase watchTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
  }) : _watchTasksUseCase = watchTasksUseCase,
       _createTaskUseCase = createTaskUseCase,
       super(const TasksState.initial());

  final WatchTasksUseCase _watchTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;

  StreamSubscription<List<CrmTask>>? _tasksSubscription;

  void watchTasks({required String companyId, String? assignedTo}) {
    emit(
      state.copyWith(
        status: TasksStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _tasksSubscription?.cancel();
    _tasksSubscription = _watchTasksUseCase(
      companyId: companyId,
      assignedTo: assignedTo,
    ).listen(
      (tasks) {
        if (isClosed) {
          return;
        }
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

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        filteredTasks: _applyFilters(state.tasks, assignedToFilter: assignedTo),
      ),
    );
  }

  Future<void> createTask({
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
      await _createTaskUseCase(companyId: companyId, task: task);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: TasksStatus.saved,
          clearMessage: true,
          lastAction: TasksAction.createTask,
        ),
      );
    } on TaskException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: error.message,
          lastAction: TasksAction.createTask,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: TasksStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: TasksAction.createTask,
        ),
      );
    }
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  List<CrmTask> _applyFilters(
    List<CrmTask> tasks, {
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    String? assignedToFilter,
    bool overrideStatusFilter = false,
    bool overridePriorityFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStatus = overrideStatusFilter
        ? statusFilter
        : statusFilter ?? state.statusFilter;
    final selectedPriority = overridePriorityFilter
        ? priorityFilter
        : priorityFilter ?? state.priorityFilter;
    final selectedAssignedTo = (assignedToFilter ?? state.assignedToFilter).trim();

    final filtered = tasks.where((task) {
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.relatedId.toLowerCase().contains(query);
      final matchesStatus = selectedStatus == null || task.status == selectedStatus;
      final matchesPriority =
          selectedPriority == null || task.priority == selectedPriority;
      final matchesAssignedTo =
          selectedAssignedTo.isEmpty || task.assignedTo == selectedAssignedTo;
      return matchesSearch && matchesStatus && matchesPriority && matchesAssignedTo;
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.dueDate ?? a.updatedAt ?? a.createdAt ?? DateTime(9999);
      final bDate = b.dueDate ?? b.updatedAt ?? b.createdAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  String _taskErrorMessage(Object error, String fallback) {
    if (error is TaskException) {
      return error.message;
    }
    return fallback;
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
