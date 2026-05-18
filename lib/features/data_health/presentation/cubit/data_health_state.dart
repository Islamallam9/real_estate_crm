import 'package:equatable/equatable.dart';

import '../../../platform/domain/entities/company_data_health_report.dart';
import '../../../users/domain/entities/user_profile.dart';

enum DataHealthStatus { initial, loading, ready, saving, failure }

class DataHealthState extends Equatable {
  const DataHealthState({
    required this.status,
    this.report,
    this.eligibleAssignees = const [],
    this.activeActionId,
    this.message,
  });

  const DataHealthState.initial() : this(status: DataHealthStatus.initial);

  final DataHealthStatus status;
  final CompanyDataHealthReport? report;
  final List<UserProfile> eligibleAssignees;
  final String? activeActionId;
  final String? message;

  DataHealthState copyWith({
    DataHealthStatus? status,
    CompanyDataHealthReport? report,
    List<UserProfile>? eligibleAssignees,
    String? activeActionId,
    String? message,
    bool clearReport = false,
    bool clearActiveAction = false,
    bool clearMessage = false,
  }) {
    return DataHealthState(
      status: status ?? this.status,
      report: clearReport ? null : report ?? this.report,
      eligibleAssignees: eligibleAssignees ?? this.eligibleAssignees,
      activeActionId: clearActiveAction ? null : activeActionId ?? this.activeActionId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, report, eligibleAssignees, activeActionId, message];
}
