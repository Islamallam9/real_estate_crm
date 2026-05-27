import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/platform_error_log.dart';
import '../../domain/usecases/mark_platform_error_resolved_usecase.dart';
import '../../domain/usecases/watch_platform_error_logs_usecase.dart';
import 'platform_observability_state.dart';

class PlatformObservabilityCubit extends Cubit<PlatformObservabilityState> {
  PlatformObservabilityCubit({
    required WatchPlatformErrorLogsUseCase watchErrorLogsUseCase,
    required MarkPlatformErrorResolvedUseCase markResolvedUseCase,
  })  : _watchErrorLogsUseCase = watchErrorLogsUseCase,
        _markResolvedUseCase = markResolvedUseCase,
        super(const PlatformObservabilityState.initial());

  final WatchPlatformErrorLogsUseCase _watchErrorLogsUseCase;
  final MarkPlatformErrorResolvedUseCase _markResolvedUseCase;

  StreamSubscription<List<PlatformErrorLog>>? _subscription;
  bool _watching = false;

  void watch() {
    if (_watching) {
      return;
    }
    _watching = true;
    emit(state.copyWith(status: PlatformObservabilityStatus.loading));
    _subscription = _watchErrorLogsUseCase().listen(
      (logs) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PlatformObservabilityStatus.ready,
              logs: logs,
              clearMessage: true,
            ),
          );
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PlatformObservabilityStatus.failure,
              message: error.toString().replaceFirst('Exception: ', ''),
            ),
          );
        }
      },
    );
  }

  void setCompany(String companyId) {
    emit(state.copyWith(companyId: companyId, clearMessage: true));
  }

  void setSeverity(PlatformErrorSeverity? severity) {
    emit(
      state.copyWith(
        severity: severity,
        clearSeverity: severity == null,
        clearMessage: true,
      ),
    );
  }

  void setSource(PlatformErrorSource? source) {
    emit(
      state.copyWith(
        source: source,
        clearSource: source == null,
        clearMessage: true,
      ),
    );
  }

  void setModule(String module) {
    emit(state.copyWith(module: module, clearMessage: true));
  }

  void setResolvedFilter(PlatformErrorResolvedFilter filter) {
    emit(state.copyWith(resolvedFilter: filter, clearMessage: true));
  }

  void setDateFilter(PlatformErrorDateFilter filter) {
    emit(state.copyWith(dateFilter: filter, clearMessage: true));
  }

  Future<bool> markResolved(PlatformErrorLog log) async {
    if (state.resolvingLogId == log.id || log.resolved) {
      return false;
    }
    emit(state.copyWith(resolvingLogId: log.id, clearMessage: true));
    try {
      await _markResolvedUseCase(logId: log.id);
      if (!isClosed) {
        emit(state.copyWith(clearResolvingLogId: true));
      }
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            message: error.toString().replaceFirst('Exception: ', ''),
            clearResolvingLogId: true,
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
