import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

enum ExportModule {
  leads,
  clients,
  deals,
  tasks,
  appointments,
  properties,
  teamPerformance,
  pipeline,
  followUps,
  auditSummary,
}

enum ExportDateRangePreset {
  allTime,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

enum ExportOutputLanguage { en, ar }

class ExportActor extends Equatable {
  const ExportActor({
    required this.companyId,
    required this.companyName,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.teamId,
    required this.teamName,
  });

  final String companyId;
  final String companyName;
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String teamId;
  final String teamName;

  @override
  List<Object?> get props => [
    companyId,
    companyName,
    uid,
    name,
    email,
    role,
    teamId,
    teamName,
  ];
}

class ExportFilters extends Equatable {
  const ExportFilters({
    this.dateRange = ExportDateRangePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.assigneeId = '',
    this.status = '',
    this.includeArchived = false,
    this.outputLanguage = ExportOutputLanguage.en,
    this.selectedColumnIds = const <String>[],
  });

  final ExportDateRangePreset dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String assigneeId;
  final String status;
  final bool includeArchived;
  final ExportOutputLanguage outputLanguage;
  final List<String> selectedColumnIds;

  ExportFilters copyWith({
    ExportDateRangePreset? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    String? assigneeId,
    String? status,
    bool? includeArchived,
    ExportOutputLanguage? outputLanguage,
    List<String>? selectedColumnIds,
    bool clearCustomDates = false,
  }) {
    return ExportFilters(
      dateRange: dateRange ?? this.dateRange,
      customStart: clearCustomDates ? null : customStart ?? this.customStart,
      customEnd: clearCustomDates ? null : customEnd ?? this.customEnd,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
      includeArchived: includeArchived ?? this.includeArchived,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      selectedColumnIds: selectedColumnIds ?? this.selectedColumnIds,
    );
  }

  @override
  List<Object?> get props => [
    dateRange,
    customStart,
    customEnd,
    assigneeId,
    status,
    includeArchived,
    outputLanguage,
    selectedColumnIds,
  ];
}

class ExportRequest extends Equatable {
  const ExportRequest({
    required this.module,
    required this.actor,
    required this.filters,
    required this.labels,
    required this.columns,
  });

  final ExportModule module;
  final ExportActor actor;
  final ExportFilters filters;
  final Map<String, String> labels;
  final List<String> columns;

  ExportRequest copyWith({
    ExportModule? module,
    ExportActor? actor,
    ExportFilters? filters,
    Map<String, String>? labels,
    List<String>? columns,
  }) {
    return ExportRequest(
      module: module ?? this.module,
      actor: actor ?? this.actor,
      filters: filters ?? this.filters,
      labels: labels ?? this.labels,
      columns: columns ?? this.columns,
    );
  }

  @override
  List<Object?> get props => [module, actor, filters, labels, columns];
}
