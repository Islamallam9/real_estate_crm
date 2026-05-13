import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_log.dart';

enum AuditLogsStatus { initial, loading, loaded, empty, failure }

class AuditLogsState extends Equatable {
  const AuditLogsState({
    required this.status,
    required this.logs,
    this.message,
  });

  const AuditLogsState.initial()
    : status = AuditLogsStatus.initial,
      logs = const <AuditLog>[],
      message = null;

  final AuditLogsStatus status;
  final List<AuditLog> logs;
  final String? message;

  AuditLogsState copyWith({
    AuditLogsStatus? status,
    List<AuditLog>? logs,
    String? message,
    bool clearMessage = false,
  }) {
    return AuditLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, logs, message];
}
