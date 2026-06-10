import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_log.dart';

enum AuditLogsStatus { initial, loading, loadingMore, loaded, empty, failure }

class AuditLogsState extends Equatable {
  const AuditLogsState({
    required this.status,
    required this.logs,
    this.pageLimit = 15,
    this.message,
  });

  const AuditLogsState.initial()
    : status = AuditLogsStatus.initial,
      logs = const <AuditLog>[],
      pageLimit = 15,
      message = null;

  final AuditLogsStatus status;
  final List<AuditLog> logs;
  final int pageLimit;
  bool get canLoadMore => logs.length >= pageLimit;
  final String? message;

  AuditLogsState copyWith({
    AuditLogsStatus? status,
    List<AuditLog>? logs,
    int? pageLimit,
    String? message,
    bool clearMessage = false,
  }) {
    return AuditLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      pageLimit: pageLimit ?? this.pageLimit,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, logs, pageLimit, message];
}
