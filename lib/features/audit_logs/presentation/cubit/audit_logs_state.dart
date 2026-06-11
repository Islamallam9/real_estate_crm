import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_log.dart';

enum AuditLogsStatus { initial, loading, loadingMore, loaded, empty, failure }

class AuditLogsState extends Equatable {
  const AuditLogsState({
    required this.status,
    required this.logs,
    this.pageLimit = 15,
    this.message,
    this.recentStatus = AuditLogsStatus.initial,
    this.recentLogs = const <AuditLog>[],
  });

  const AuditLogsState.initial()
    : status = AuditLogsStatus.initial,
      logs = const <AuditLog>[],
      pageLimit = 15,
      message = null,
      recentStatus = AuditLogsStatus.initial,
      recentLogs = const <AuditLog>[];

  final AuditLogsStatus status;
  final List<AuditLog> logs;
  final int pageLimit;
  bool get canLoadMore => logs.length >= pageLimit;
  final String? message;

  /// Dedicated, isolated stream state for Dashboard Recent Activity.
  ///
  /// The full Audit Logs page and Dashboard rail must not fight over the same
  /// `logs` list. If the Dashboard uses the main AuditLogs page state, opening
  /// filters/pages or restarting a quick-action scope can make the rail show a
  /// new row for a moment, then disappear when another watcher emits. Keeping
  /// recent activity separate makes it realtime and stable.
  final AuditLogsStatus recentStatus;
  final List<AuditLog> recentLogs;

  AuditLogsState copyWith({
    AuditLogsStatus? status,
    List<AuditLog>? logs,
    int? pageLimit,
    String? message,
    bool clearMessage = false,
    AuditLogsStatus? recentStatus,
    List<AuditLog>? recentLogs,
  }) {
    return AuditLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      pageLimit: pageLimit ?? this.pageLimit,
      message: clearMessage ? null : message ?? this.message,
      recentStatus: recentStatus ?? this.recentStatus,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }

  @override
  List<Object?> get props => [
        status,
        logs,
        pageLimit,
        message,
        recentStatus,
        recentLogs,
      ];
}
