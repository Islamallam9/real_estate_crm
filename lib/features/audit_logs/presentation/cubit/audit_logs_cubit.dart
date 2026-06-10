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
  static const int defaultPageLimit = 15;
  static const int pageIncrement = 15;
  String? _companyId;
  String? _managerId;
  String? _teamId;
  AuditLogModule? _module;
  AuditLogAction? _action;
  String? _actorId;
  bool _hasSearchFilter = false;
  DateTime? _startAt;
  DateTime? _endAt;

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
    int? limit,
    bool resetPage = false,
  }) {
    if (companyId.trim().isEmpty) {
      return;
    }
    _companyId = companyId;
    _managerId = managerId;
    _teamId = teamId;
    _module = module;
    _action = action;
    _actorId = actorId;
    _hasSearchFilter = hasSearchFilter;
    _startAt = startAt;
    _endAt = endAt;

    final pageLimit = resetPage ? defaultPageLimit : limit ?? state.pageLimit;
    final isLoadingMore = state.logs.isNotEmpty && pageLimit > state.pageLimit;

    emit(
      state.copyWith(
        status: isLoadingMore ? AuditLogsStatus.loadingMore : AuditLogsStatus.loading,
        pageLimit: pageLimit,
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
      limit: pageLimit,
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

  void loadMoreAuditLogs({
    String? companyId,
    String? managerId,
    String? teamId,
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    bool hasSearchFilter = false,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    final effectiveCompanyId = companyId ?? _companyId;
    if (effectiveCompanyId == null ||
        effectiveCompanyId.trim().isEmpty ||
        state.status == AuditLogsStatus.loading ||
        state.status == AuditLogsStatus.loadingMore ||
        !state.canLoadMore) {
      return;
    }
    watchAuditLogs(
      companyId: effectiveCompanyId,
      managerId: managerId ?? _managerId,
      teamId: teamId ?? _teamId,
      module: module ?? _module,
      action: action ?? _action,
      actorId: actorId ?? _actorId,
      hasSearchFilter: hasSearchFilter || _hasSearchFilter,
      startAt: startAt ?? _startAt,
      endAt: endAt ?? _endAt,
      limit: state.pageLimit + pageIncrement,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
