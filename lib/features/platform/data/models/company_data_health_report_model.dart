import '../../domain/entities/company_data_health_report.dart';

class CompanyDataHealthReportModel extends CompanyDataHealthReport {
  const CompanyDataHealthReportModel({
    required super.companyId,
    required super.generatedAt,
    required super.missingSnapshots,
    required super.invalidAssignees,
    required super.inactiveAssignees,
    required super.staleTeamSnapshots,
    required super.issues,
  });

  factory CompanyDataHealthReportModel.fromMap(Map<String, dynamic> data) {
    final counts = Map<String, dynamic>.from(
      data['counts'] as Map? ?? const {},
    );
    final rawIssues = data['issues'] as List? ?? const [];
    return CompanyDataHealthReportModel(
      companyId: data['companyId'] as String? ?? '',
      generatedAt: DateTime.tryParse(data['generatedAt'] as String? ?? ''),
      missingSnapshots: _intFrom(counts['missingSnapshots']),
      invalidAssignees: _intFrom(counts['invalidAssignees']),
      inactiveAssignees: _intFrom(counts['inactiveAssignees']),
      staleTeamSnapshots: _intFrom(counts['staleTeamSnapshots']),
      issues: rawIssues
          .whereType<Map>()
          .map((issue) => DataHealthIssueModel.fromMap(
                Map<String, dynamic>.from(issue),
              ))
          .toList(growable: false),
    );
  }
}

int _intFrom(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

class DataHealthIssueModel extends DataHealthIssue {
  const DataHealthIssueModel({
    required super.module,
    required super.recordId,
    required super.title,
    required super.assignedTo,
    required super.assignedToName,
    required super.issueType,
    required super.suggestedAction,
    required super.canBackfill,
  });

  factory DataHealthIssueModel.fromMap(Map<String, dynamic> data) {
    return DataHealthIssueModel(
      module: data['module'] as String? ?? '',
      recordId: data['recordId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      issueType: data['issueType'] as String? ?? '',
      suggestedAction: data['suggestedAction'] as String? ?? '',
      canBackfill: data['canBackfill'] as bool? ?? false,
    );
  }
}
