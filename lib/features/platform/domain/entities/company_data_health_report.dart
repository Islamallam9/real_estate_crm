import 'package:equatable/equatable.dart';

class CompanyDataHealthReport extends Equatable {
  const CompanyDataHealthReport({
    required this.companyId,
    required this.generatedAt,
    required this.missingSnapshots,
    required this.invalidAssignees,
    required this.inactiveAssignees,
    required this.staleTeamSnapshots,
    required this.issues,
  });

  final String companyId;
  final DateTime? generatedAt;
  final int missingSnapshots;
  final int invalidAssignees;
  final int inactiveAssignees;
  final int staleTeamSnapshots;
  final List<DataHealthIssue> issues;

  bool get hasIssues =>
      missingSnapshots > 0 ||
      invalidAssignees > 0 ||
      inactiveAssignees > 0 ||
      staleTeamSnapshots > 0 ||
      issues.isNotEmpty;

  @override
  List<Object?> get props => [
        companyId,
        generatedAt,
        missingSnapshots,
        invalidAssignees,
        inactiveAssignees,
        staleTeamSnapshots,
        issues,
      ];
}

class DataHealthIssue extends Equatable {
  const DataHealthIssue({
    required this.module,
    required this.recordId,
    required this.title,
    required this.assignedTo,
    required this.assignedToName,
    required this.managerId,
    required this.managerName,
    required this.issueType,
    required this.suggestedAction,
    required this.canBackfill,
  });

  final String module;
  final String recordId;
  final String title;
  final String assignedTo;
  final String assignedToName;
  final String managerId;
  final String managerName;
  final String issueType;
  final String suggestedAction;
  final bool canBackfill;

  @override
  List<Object?> get props => [
        module,
        recordId,
        title,
        assignedTo,
        assignedToName,
        managerId,
        managerName,
        issueType,
        suggestedAction,
        canBackfill,
      ];
}
