import 'package:equatable/equatable.dart';

import '../../domain/entities/crm_task.dart';
import '../../domain/entities/task_related_record_option.dart';

enum TasksStatus { initial, loading, loaded, saving, saved, empty, failure }

enum TasksAction { none, createTask, updateTask, markCompleted, cancelTask }

enum TaskRelatedRecordsStatus { initial, loading, loaded, empty, failure }

enum TaskDueDateFilter { overdue, today, upcoming }

class TasksState extends Equatable {
  const TasksState({
    required this.status,
    this.tasks = const [],
    this.filteredTasks = const [],
    this.selectedTask,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
    this.dueDateFilter,
    this.assignedToFilter = '',
    this.relatedRecordsStatus = TaskRelatedRecordsStatus.initial,
    this.relatedRecordOptions = const [],
    this.relatedRecordsType,
    this.message,
    this.relatedRecordsMessage,
    this.lastAction = TasksAction.none,
  });

  const TasksState.initial()
    : status = TasksStatus.initial,
      tasks = const [],
      filteredTasks = const [],
      selectedTask = null,
      searchQuery = '',
      statusFilter = null,
      priorityFilter = null,
      dueDateFilter = null,
      assignedToFilter = '',
      relatedRecordsStatus = TaskRelatedRecordsStatus.initial,
      relatedRecordOptions = const [],
      relatedRecordsType = null,
      message = null,
      relatedRecordsMessage = null,
      lastAction = TasksAction.none;

  final TasksStatus status;
  final List<CrmTask> tasks;
  final List<CrmTask> filteredTasks;
  final CrmTask? selectedTask;
  final String searchQuery;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final TaskDueDateFilter? dueDateFilter;
  final String assignedToFilter;
  final TaskRelatedRecordsStatus relatedRecordsStatus;
  final List<TaskRelatedRecordOption> relatedRecordOptions;
  final TaskRelatedType? relatedRecordsType;
  final String? message;
  final String? relatedRecordsMessage;
  final TasksAction lastAction;

  TasksState copyWith({
    TasksStatus? status,
    List<CrmTask>? tasks,
    List<CrmTask>? filteredTasks,
    CrmTask? selectedTask,
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    TaskDueDateFilter? dueDateFilter,
    String? assignedToFilter,
    TaskRelatedRecordsStatus? relatedRecordsStatus,
    List<TaskRelatedRecordOption>? relatedRecordOptions,
    TaskRelatedType? relatedRecordsType,
    String? message,
    String? relatedRecordsMessage,
    TasksAction? lastAction,
    bool clearStatusFilter = false,
    bool clearPriorityFilter = false,
    bool clearDueDateFilter = false,
    bool clearMessage = false,
    bool clearRelatedRecordsMessage = false,
    bool clearLastAction = false,
    bool clearSelectedTask = false,
    bool clearRelatedRecords = false,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      selectedTask: clearSelectedTask ? null : selectedTask ?? this.selectedTask,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      priorityFilter: clearPriorityFilter
          ? null
          : priorityFilter ?? this.priorityFilter,
      dueDateFilter: clearDueDateFilter
          ? null
          : dueDateFilter ?? this.dueDateFilter,
      assignedToFilter: assignedToFilter ?? this.assignedToFilter,
      relatedRecordsStatus: clearRelatedRecords
          ? TaskRelatedRecordsStatus.initial
          : relatedRecordsStatus ?? this.relatedRecordsStatus,
      relatedRecordOptions: clearRelatedRecords
          ? const []
          : relatedRecordOptions ?? this.relatedRecordOptions,
      relatedRecordsType: clearRelatedRecords
          ? null
          : relatedRecordsType ?? this.relatedRecordsType,
      message: clearMessage ? null : message ?? this.message,
      relatedRecordsMessage: clearRelatedRecordsMessage
          ? null
          : relatedRecordsMessage ?? this.relatedRecordsMessage,
      lastAction: clearLastAction ? TasksAction.none : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    filteredTasks,
    selectedTask,
    searchQuery,
    statusFilter,
    priorityFilter,
    dueDateFilter,
    assignedToFilter,
    relatedRecordsStatus,
    relatedRecordOptions,
    relatedRecordsType,
    message,
    relatedRecordsMessage,
    lastAction,
  ];
}
