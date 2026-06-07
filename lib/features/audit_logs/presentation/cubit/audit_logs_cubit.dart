import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/usecases/watch_audit_logs_usecase.dart';
import 'audit_logs_state.dart';

class AuditLogsCubit extends Cubit<AuditLogsState> {
  AuditLogsCubit({required WatchAuditLogsUseCase watchAuditLogsUseCase})
    : _watchAuditLogsUseCase = watchAuditLogsUseCase,
      super(const AuditLogsState.initial());

  final WatchAuditLogsUseCase _watchAuditLogsUseCase;

  StreamSubscription<List<AuditLog>>? _subscription;

  void watchAuditLogs({
    required String companyId,
    String? managerId,
    String? teamId,
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    bool hasSearchFilter = false,
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  }) {
    if (companyId.trim().isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: AuditLogsStatus.loading,
        clearMessage: true,
      ),
    );
    _subscription?.cancel();
    _subscription = _watchAuditLogsUseCase(
      companyId: companyId,
      managerId: managerId,
      teamId: teamId,
      module: module,
      action: action,
      actorId: actorId,
      hasSearchFilter: hasSearchFilter,
      startAt: startAt,
      endAt: endAt,
      limit: limit,
    ).listen(
      (logs) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: logs.isEmpty
                ? AuditLogsStatus.empty
                : AuditLogsStatus.loaded,
            logs: logs,
            clearMessage: true,
          ),
        );
      },
      onError: (_) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: AuditLogsStatus.failure,
            logs: const <AuditLog>[],
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
