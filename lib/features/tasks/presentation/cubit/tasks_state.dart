import 'package:equatable/equatable.dart';

import '../../domain/entities/crm_task.dart';

enum TasksStatus { initial, loading, loaded, saving, saved, empty, failure }

enum TasksAction { none, createTask }

class TasksState extends Equatable {
  const TasksState({
    required this.status,
    this.tasks = const [],
    this.filteredTasks = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
    this.assignedToFilter = '',
    this.message,
    this.lastAction = TasksAction.none,
  });

  const TasksState.initial()
    : status = TasksStatus.initial,
      tasks = const [],
      filteredTasks = const [],
      searchQuery = '',
      statusFilter = null,
      priorityFilter = null,
      assignedToFilter = '',
      message = null,
      lastAction = TasksAction.none;

  final TasksStatus status;
  final List<CrmTask> tasks;
  final List<CrmTask> filteredTasks;
  final String searchQuery;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String assignedToFilter;
  final String? message;
  final TasksAction lastAction;

  TasksState copyWith({
    TasksStatus? status,
    List<CrmTask>? tasks,
    List<CrmTask>? filteredTasks,
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    String? assignedToFilter,
    String? message,
    TasksAction? lastAction,
    bool clearStatusFilter = false,
    bool clearPriorityFilter = false,
    bool clearMessage = false,
    bool clearLastAction = false,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      priorityFilter: clearPriorityFilter
          ? null
          : priorityFilter ?? this.priorityFilter,
      assignedToFilter: assignedToFilter ?? this.assignedToFilter,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction ? TasksAction.none : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    filteredTasks,
    searchQuery,
    statusFilter,
    priorityFilter,
    assignedToFilter,
    message,
    lastAction,
  ];
}
