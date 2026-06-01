import 'package:equatable/equatable.dart';

import '../../domain/entities/export_assignee.dart';
import '../../domain/entities/export_request.dart';
import '../../domain/entities/export_result.dart';

enum ExportStatus { initial, generating, success, failure }

class ExportState extends Equatable {
  const ExportState({
    this.status = ExportStatus.initial,
    this.module = ExportModule.leads,
    this.selectedModules = const <ExportModule>[ExportModule.leads],
    this.filters = const ExportFilters(),
    this.assignees = const <ExportAssignee>[],
    this.result,
    this.message,
    this.advancedColumns = false,
    this.selectedColumns = const <String>[],
  });

  final ExportStatus status;
  final ExportModule module;
  final List<ExportModule> selectedModules;
  final ExportFilters filters;
  final List<ExportAssignee> assignees;
  final ExportResult? result;
  final String? message;
  final bool advancedColumns;
  final List<String> selectedColumns;

  ExportState copyWith({
    ExportStatus? status,
    ExportModule? module,
    List<ExportModule>? selectedModules,
    ExportFilters? filters,
    List<ExportAssignee>? assignees,
    ExportResult? result,
    String? message,
    bool? advancedColumns,
    List<String>? selectedColumns,
    bool clearResult = false,
    bool clearMessage = false,
  }) {
    return ExportState(
      status: status ?? this.status,
      module: module ?? this.module,
      selectedModules: selectedModules ?? this.selectedModules,
      filters: filters ?? this.filters,
      assignees: assignees ?? this.assignees,
      result: clearResult ? null : result ?? this.result,
      message: clearMessage ? null : message ?? this.message,
      advancedColumns: advancedColumns ?? this.advancedColumns,
      selectedColumns: selectedColumns ?? this.selectedColumns,
    );
  }

  @override
  List<Object?> get props => [
    status,
    module,
    selectedModules,
    filters,
    assignees,
    result,
    message,
    advancedColumns,
    selectedColumns,
  ];
}
