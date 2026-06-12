import 'dart:async';

import 'package:flutter/foundation.dart';
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
  StreamSubscription<List<AuditLog>>? _recentActivitySubscription;
  String? _auditLogsWatchKey;
  String? _recentActivityWatchKey;
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
    bool force = false,
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

    final pageLimit = resetPage
        ? (limit ?? defaultPageLimit)
        : limit ?? state.pageLimit;
    final isLoadingMore = state.logs.isNotEmpty && pageLimit > state.pageLimit;
    final watchKey = [
      companyId.trim(),
      managerId?.trim() ?? '',
      teamId?.trim() ?? '',
      module?.name ?? '',
      action?.name ?? '',
      actorId?.trim() ?? '',
      hasSearchFilter ? 'search' : '',
      startAt?.toIso8601String() ?? '',
      endAt?.toIso8601String() ?? '',
      pageLimit.toString(),
    ].join('|');
    if (!force &&
        _auditLogsWatchKey == watchKey &&
        _subscription != null &&
        state.status != AuditLogsStatus.failure) {
      _debugAuditCubit(
        'watchAuditLogs skipped duplicate company=$companyId '
        'managerId=${managerId ?? ''} teamId=${teamId ?? ''} '
        'module=${module?.name ?? ''} action=${action?.name ?? ''} '
        'actorId=${actorId ?? ''} limit=$pageLimit',
      );
      return;
    }
    _auditLogsWatchKey = watchKey;

    emit(
      state.copyWith(
        status: isLoadingMore ? AuditLogsStatus.loadingMore : AuditLogsStatus.loading,
        pageLimit: pageLimit,
        clearMessage: true,
      ),
    );
    _subscription?.cancel();
    _debugAuditCubit(
      'watchAuditLogs start company=$companyId managerId=${managerId ?? ''} '
      'teamId=${teamId ?? ''} module=${module?.name ?? ''} '
      'action=${action?.name ?? ''} actorId=${actorId ?? ''} '
      'limit=$pageLimit resetPage=$resetPage force=$force',
    );
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
        _debugAuditCubit(
          'watchAuditLogs data company=$companyId managerId=${managerId ?? ''} '
          'teamId=${teamId ?? ''} count=${logs.length} '
          'ids=${logs.take(8).map((log) => log.id).join(',')}',
        );
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
      onError: (Object error, StackTrace stackTrace) {
        if (isClosed) {
          return;
        }
        _debugAuditCubit(
          'watchAuditLogs error company=$companyId managerId=${managerId ?? ''} '
          'teamId=${teamId ?? ''}: $error',
          stackTrace,
        );
        _auditLogsWatchKey = null;
        emit(
          state.copyWith(
            status: AuditLogsStatus.failure,
            logs: const <AuditLog>[],
          ),
        );
      },
    );
  }


  void watchDashboardRecentActivity({
    required String companyId,
    String? managerId,
    String? teamId,
    int limit = 8,
    bool force = false,
  }) {
    if (companyId.trim().isEmpty) {
      return;
    }

    final watchKey = [
      companyId.trim(),
      managerId?.trim() ?? '',
      teamId?.trim() ?? '',
      limit.toString(),
    ].join('|');
    if (!force &&
        _recentActivityWatchKey == watchKey &&
        _recentActivitySubscription != null) {
      _debugAuditCubit(
        'recentActivity skipped duplicate company=$companyId '
        'managerId=${managerId ?? ''} teamId=${teamId ?? ''} limit=$limit',
      );
      return;
    }
    _recentActivityWatchKey = watchKey;

    emit(
      state.copyWith(
        recentStatus: state.recentLogs.isEmpty
            ? AuditLogsStatus.loading
            : AuditLogsStatus.loaded,
        clearMessage: true,
      ),
    );
    _recentActivitySubscription?.cancel();
    _debugAuditCubit(
      'recentActivity start company=$companyId managerId=${managerId ?? ''} '
      'teamId=${teamId ?? ''} limit=$limit force=$force',
    );
    _recentActivitySubscription = _watchAuditLogsUseCase(
      companyId: companyId,
      managerId: managerId,
      teamId: teamId,
      limit: limit,
    ).listen(
      (logs) {
        if (isClosed) {
          return;
        }
        _debugAuditCubit(
          'recentActivity data company=$companyId managerId=${managerId ?? ''} '
          'teamId=${teamId ?? ''} count=${logs.length} '
          'ids=${logs.take(8).map((log) => log.id).join(',')}',
        );
        emit(
          state.copyWith(
            recentStatus: logs.isEmpty
                ? AuditLogsStatus.empty
                : AuditLogsStatus.loaded,
            recentLogs: logs,
            clearMessage: true,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (isClosed) {
          return;
        }
        _debugAuditCubit(
          'recentActivity error company=$companyId managerId=${managerId ?? ''} '
          'teamId=${teamId ?? ''}: $error',
          stackTrace,
        );
        _recentActivityWatchKey = null;
        _recentActivitySubscription?.cancel();
        _recentActivitySubscription = null;
        emit(
          state.copyWith(
            recentStatus: state.recentLogs.isEmpty
                ? AuditLogsStatus.failure
                : AuditLogsStatus.loaded,
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
    _recentActivitySubscription?.cancel();
    return super.close();
  }
}

void _debugAuditCubit(String message, [StackTrace? stackTrace]) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarAuditCubitDebug $message');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}
