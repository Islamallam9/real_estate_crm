import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/stats/module_kpi_counts_data_source.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/errors/appointment_exception.dart';
import '../../domain/usecases/get_appointment_related_record_options_usecase.dart';
import '../../domain/usecases/save_appointment_usecase.dart';
import '../../domain/usecases/watch_appointment_usecase.dart';
import '../../domain/usecases/watch_appointments_usecase.dart';
import 'appointments_state.dart';

void _masarAppointmentsCubitDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarAppointmentsCubitDebug $message');
}

class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit({
    required WatchAppointmentsUseCase watchAppointmentsUseCase,
    required WatchAppointmentUseCase watchAppointmentUseCase,
    required SaveAppointmentUseCase saveAppointmentUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
    required GetAppointmentRelatedRecordOptionsUseCase
        getRelatedRecordOptionsUseCase,
  })  : _watchAppointmentsUseCase = watchAppointmentsUseCase,
        _watchAppointmentUseCase = watchAppointmentUseCase,
        _saveAppointmentUseCase = saveAppointmentUseCase,
        _createAuditLogUseCase = createAuditLogUseCase,
        _getRelatedRecordOptionsUseCase = getRelatedRecordOptionsUseCase,
        super(const AppointmentsState.initial());

  final WatchAppointmentsUseCase _watchAppointmentsUseCase;
  final WatchAppointmentUseCase _watchAppointmentUseCase;
  final SaveAppointmentUseCase _saveAppointmentUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;
  final GetAppointmentRelatedRecordOptionsUseCase
      _getRelatedRecordOptionsUseCase;
  final FirestoreModuleKpiCountsDataSource _countsDataSource =
      FirestoreModuleKpiCountsDataSource();

  StreamSubscription<List<Appointment>>? _appointmentsSubscription;
  StreamSubscription<Appointment?>? _appointmentSubscription;
  String? _watchedCompanyId;
  String? _watchedAssignedTo;
  String? _watchedManagerId;
  String? _watchedTeamId;
  DateTime? _watchedRangeStart;
  DateTime? _watchedRangeEnd;
  Future<void>? _inFlightKpiRefresh;
  String? _inFlightKpiRefreshKey;
  String? _lastSuccessfulKpiRefreshKey;
  DateTime? _lastSuccessfulKpiRefreshAt;
  int _kpiRefreshSerial = 0;
  bool _isClosing = false;
  static const Duration _streamKpiRefreshDebounce =
      Duration(milliseconds: 1500);
  static const int _defaultPageLimit = 15;
  static const int _pageIncrement = 15;
  static const List<String> _kpiCountKeys = <String>[
    'total',
    'listTotal',
    'today',
    'upcoming',
    'missed',
    'completed',
  ];
  static const int _dashboardWatchLimit = 500;
  static const int _filterModeWatchLimit = 500;
  final InitialLoadTimeout _appointmentsInitialLoadTimeout =
      InitialLoadTimeout();
  final InitialLoadTimeout _appointmentInitialLoadTimeout =
      InitialLoadTimeout();

  void watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    int? limit,
    bool resetPage = true,
    bool usePagination = true,
  }) {
    _watchedCompanyId = companyId;
    _watchedAssignedTo = assignedTo;
    _watchedManagerId = managerId;
    _watchedTeamId = teamId;
    _watchedRangeStart = rangeStart;
    _watchedRangeEnd = rangeEnd;
    final pageLimit = usePagination
        ? (resetPage ? _defaultPageLimit : limit ?? state.pageLimit)
        : state.pageLimit;
    final watchLimit = usePagination
        ? _effectiveWatchLimit(pageLimit)
        : _dashboardWatchLimit;
    _masarAppointmentsCubitDebug(
      'watchAppointments start company=$companyId assignedTo=$assignedTo '
      'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
      'rangeEnd=$rangeEnd usePagination=$usePagination resetPage=$resetPage '
      'pageLimit=$pageLimit watchLimit=$watchLimit '
      'currentRows=${state.appointments.length} '
      'kpi=${_debugKpiCounts(state.kpiCounts)}',
    );
    emit(
      state.copyWith(
        status: resetPage || state.appointments.isEmpty
            ? AppointmentsStatus.loading
            : AppointmentsStatus.loadingMore,
        pageLimit: pageLimit,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    if (resetPage || !state.kpiCounts.hasAll(_kpiCountKeys)) {
      unawaited(_refreshKpiCounts(reason: 'watch-start'));
    }
    _appointmentsSubscription?.cancel();
    _appointmentsInitialLoadTimeout.start(() {
      if (isClosed ||
          (state.status != AppointmentsStatus.loading &&
              state.status != AppointmentsStatus.loadingMore) ||
          state.appointments.isNotEmpty) {
        return;
      }
      _masarAppointmentsCubitDebug(
        'watchAppointments timeout company=$companyId assignedTo=$assignedTo '
        'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
        'rangeEnd=$rangeEnd watchLimit=$watchLimit rows=${state.appointments.length} '
        'status=${state.status} kpi=${_debugKpiCounts(state.kpiCounts)}',
      );
      emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _appointmentsSubscription = _watchAppointmentsUseCase(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      limit: watchLimit,
    ).listen(
      (appointments) {
        if (isClosed) {
          return;
        }
        _masarAppointmentsCubitDebug(
          'watchAppointments data company=$companyId count=${appointments.length} '
          'assignedTo=$assignedTo managerId=$managerId teamId=$teamId '
          'rangeStart=$rangeStart rangeEnd=$rangeEnd watchLimit=$watchLimit',
        );
        _appointmentsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: appointments.isEmpty
                ? AppointmentsStatus.empty
                : AppointmentsStatus.loaded,
            appointments: appointments,
            filteredAppointments: _applyFilters(appointments),
            pageLimit: pageLimit,
            clearMessage: true,
          ),
        );
        unawaited(_refreshKpiCounts(reason: 'stream-data'));
        _debugCheckKpiInvariant();
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        _masarAppointmentsCubitDebug(
          'watchAppointments error company=$companyId assignedTo=$assignedTo '
          'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
          'rangeEnd=$rangeEnd watchLimit=$watchLimit '
          'errorType=${error.runtimeType} error=$error',
        );
        _appointmentsInitialLoadTimeout.complete();
        if (state.appointments.isNotEmpty) {
          _masarAppointmentsCubitDebug(
            'watchAppointments nonBlockingErrorSuppressed '
            'company=$companyId rows=${state.appointments.length} '
            'message=${_errorMessage(error)}',
          );
          emit(
            state.copyWith(
              status: AppointmentsStatus.loaded,
              clearMessage: true,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: AppointmentsStatus.failure,
            message: _errorMessage(error),
          ),
        );
      },
    );
  }


  Future<void> _refreshKpiCounts({
    required String reason,
    bool force = false,
  }) {
    if (_isClosing || isClosed) {
      return Future<void>.value();
    }
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return Future<void>.value();
    }

    final scopeKey = _kpiScopeKey(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      rangeStart: _watchedRangeStart,
      rangeEnd: _watchedRangeEnd,
    );
    final inFlight = _inFlightKpiRefresh;
    if (!force && inFlight != null && _inFlightKpiRefreshKey == scopeKey) {
      _masarAppointmentsCubitDebug(
        'kpi skipped duplicate inFlight reason=$reason key=$scopeKey',
      );
      return inFlight;
    }

    final lastAt = _lastSuccessfulKpiRefreshAt;
    if (!force &&
        reason == 'stream-data' &&
        _lastSuccessfulKpiRefreshKey == scopeKey &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _streamKpiRefreshDebounce) {
      _masarAppointmentsCubitDebug(
        'kpi skipped recent stream-data key=$scopeKey',
      );
      return Future<void>.value();
    }

    final refreshSerial = ++_kpiRefreshSerial;
    final refresh = _runKpiRefresh(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      rangeStart: _watchedRangeStart,
      rangeEnd: _watchedRangeEnd,
      scopeKey: scopeKey,
      reason: reason,
      refreshSerial: refreshSerial,
    );
    _inFlightKpiRefresh = refresh;
    _inFlightKpiRefreshKey = scopeKey;
    refresh.whenComplete(() {
      if (identical(_inFlightKpiRefresh, refresh)) {
        _inFlightKpiRefresh = null;
        _inFlightKpiRefreshKey = null;
      }
    });
    return refresh;
  }

  Future<void> _runKpiRefresh({
    required String companyId,
    required String? assignedTo,
    required String? managerId,
    required String? teamId,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
    required String scopeKey,
    required String reason,
    required int refreshSerial,
  }) async {
    try {
      _masarAppointmentsCubitDebug(
        'kpi start reason=$reason company=$companyId assignedTo=$assignedTo '
        'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
        'rangeEnd=$rangeEnd key=$scopeKey',
      );
      final counts = await _countsDataSource.appointmentCounts(
        companyId: companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      if (!_isClosing &&
          !isClosed &&
          _kpiRefreshSerial == refreshSerial &&
          _currentKpiScopeKey() == scopeKey) {
        _lastSuccessfulKpiRefreshKey = scopeKey;
        _lastSuccessfulKpiRefreshAt = DateTime.now();
        _masarAppointmentsCubitDebug(
          'kpi success reason=$reason company=$companyId assignedTo=$assignedTo '
          'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
          'rangeEnd=$rangeEnd kpi=${_debugKpiCounts(counts)}',
        );
        emit(state.copyWith(kpiCounts: counts));
        _debugCheckKpiInvariant();
      } else {
        _masarAppointmentsCubitDebug(
          'kpi discarded stale reason=$reason company=$companyId key=$scopeKey '
          'serial=$refreshSerial latestSerial=$_kpiRefreshSerial '
          'currentKey=${_currentKpiScopeKey()}',
        );
      }
    } catch (error) {
      _masarAppointmentsCubitDebug(
        'kpi error reason=$reason company=$companyId assignedTo=$assignedTo '
        'managerId=$managerId teamId=$teamId rangeStart=$rangeStart '
        'rangeEnd=$rangeEnd errorType=${error.runtimeType} error=$error',
      );
      if (!_isClosing &&
          !isClosed &&
          _kpiRefreshSerial == refreshSerial &&
          _currentKpiScopeKey() == scopeKey) {
        emit(
          state.copyWith(
            kpiCounts: ModuleKpiCounts(
              const <String, int>{},
              failedKeys: _kpiCountKeys.toSet(),
            ),
          ),
        );
      }
    }
  }

  String? _currentKpiScopeKey() {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return null;
    }
    return _kpiScopeKey(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      rangeStart: _watchedRangeStart,
      rangeEnd: _watchedRangeEnd,
    );
  }

  String _kpiScopeKey({
    required String companyId,
    required String? assignedTo,
    required String? managerId,
    required String? teamId,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    return <String>[
      companyId.trim(),
      assignedTo?.trim() ?? '',
      managerId?.trim() ?? '',
      teamId?.trim() ?? '',
      rangeStart?.toUtc().millisecondsSinceEpoch.toString() ?? '',
      rangeEnd?.toUtc().millisecondsSinceEpoch.toString() ?? '',
    ].join('|');
  }

  String _debugKpiCounts(ModuleKpiCounts counts) {
    final values = counts.values.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(',');
    final failed = counts.failedKeys.join(',');
    return 'values={$values} failed=[$failed]';
  }

  void _debugCheckKpiInvariant() {
    debugCheckModuleKpiInvariant(
      module: 'appointments',
      loadedRows: state.appointments.length,
      totalCount: state.kpiCounts.valueOrNull('listTotal'),
      hasLocalFilters: state.hasLocalTableFilters,
      scopeLabel: 'listWindow',
    );
  }

  int _effectiveWatchLimit(int pageLimit) {
    // Appointment workspaces are calendar/attention driven, not a plain newest
    // table. Loading only the first paged slice can hide today's appointment
    // while the KPI count correctly reports it. Keep the watch bounded, but
    // wide enough for the rolling calendar and attention views to stay truthful.
    final workspaceLimit = pageLimit > _filterModeWatchLimit
        ? pageLimit
        : _filterModeWatchLimit;
    return workspaceLimit;
  }

  void loadMoreAppointments() {
    final companyId = _watchedCompanyId;
    if (companyId == null ||
        companyId.isEmpty ||
        state.status == AppointmentsStatus.loading ||
        state.status == AppointmentsStatus.loadingMore) {
      return;
    }

    final nextLimit = state.pageLimit + _pageIncrement;
    if (state.filteredAppointments.length > state.pageLimit) {
      emit(state.copyWith(pageLimit: nextLimit));
      _debugCheckKpiInvariant();
      return;
    }
    if (!state.canLoadMore) {
      return;
    }

    watchAppointments(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      rangeStart: _watchedRangeStart,
      rangeEnd: _watchedRangeEnd,
      limit: nextLimit,
      resetPage: false,
    );
  }

  void _reloadCurrentAppointmentScopeAfterFilterChange() {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return;
    }
    watchAppointments(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      rangeStart: _watchedRangeStart,
      rangeEnd: _watchedRangeEnd,
      resetPage: true,
    );
  }

  void watchAppointment({
    required String companyId,
    required String appointmentId,
  }) {
    emit(
      state.copyWith(
        status: AppointmentsStatus.loading,
        clearMessage: true,
        clearSelectedAppointment: true,
      ),
    );
    _appointmentSubscription?.cancel();
    _appointmentInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != AppointmentsStatus.loading ||
          state.selectedAppointment != null) {
        return;
      }
      emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _appointmentSubscription = _watchAppointmentUseCase(
      companyId: companyId,
      appointmentId: appointmentId,
    ).listen(
      (appointment) {
        if (isClosed) {
          return;
        }
        _appointmentInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: appointment == null
                ? AppointmentsStatus.empty
                : AppointmentsStatus.loaded,
            selectedAppointment: appointment,
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        _appointmentInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: AppointmentsStatus.failure,
            message: _errorMessage(error),
          ),
        );
      },
    );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        pageLimit: _defaultPageLimit,
        filteredAppointments:
            _applyFilters(state.appointments, searchQuery: query),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void setStatusFilter(AppointmentStatus? statusFilter) {
    emit(
      state.copyWith(
        statusFilter: statusFilter,
        pageLimit: _defaultPageLimit,
        clearStatusFilter: statusFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          statusFilter: statusFilter,
          overrideStatusFilter: true,
        ),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void setTypeFilter(AppointmentType? typeFilter) {
    emit(
      state.copyWith(
        typeFilter: typeFilter,
        pageLimit: _defaultPageLimit,
        clearTypeFilter: typeFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          typeFilter: typeFilter,
          overrideTypeFilter: true,
        ),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void setDateFilter(AppointmentDateFilter? dateFilter) {
    emit(
      state.copyWith(
        dateFilter: dateFilter,
        pageLimit: _defaultPageLimit,
        clearDateFilter: dateFilter == null,
        clearSelectedDateFilter: true,
        filteredAppointments: _applyFilters(
          state.appointments,
          dateFilter: dateFilter,
          overrideDateFilter: true,
          selectedDateFilter: null,
          overrideSelectedDateFilter: true,
        ),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void setSelectedDateFilter(DateTime? selectedDateFilter) {
    emit(
      state.copyWith(
        selectedDateFilter: selectedDateFilter,
        pageLimit: _defaultPageLimit,
        clearSelectedDateFilter: selectedDateFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          selectedDateFilter: selectedDateFilter,
          overrideSelectedDateFilter: true,
        ),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void setCalendarView(AppointmentCalendarView view) {
    emit(
      state.copyWith(
        calendarView: view,
        selectedCalendarDate:
            state.selectedCalendarDate ?? _dateOnly(DateTime.now()),
      ),
    );
  }

  void setSelectedCalendarDate(DateTime selectedDate) {
    emit(
      state.copyWith(
        selectedCalendarDate: _dateOnly(selectedDate),
      ),
    );
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        pageLimit: _defaultPageLimit,
        filteredAppointments:
            _applyFilters(state.appointments, assignedToFilter: assignedTo),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: '',
        pageLimit: _defaultPageLimit,
        clearStatusFilter: true,
        clearTypeFilter: true,
        clearDateFilter: true,
        clearSelectedDateFilter: true,
        filteredAppointments: _applyFilters(
          state.appointments,
          searchQuery: '',
          statusFilter: null,
          typeFilter: null,
          dateFilter: null,
          selectedDateFilter: null,
          assignedToFilter: '',
          overrideStatusFilter: true,
          overrideTypeFilter: true,
          overrideDateFilter: true,
          overrideSelectedDateFilter: true,
        ),
      ),
    );
    _reloadCurrentAppointmentScopeAfterFilterChange();
  }

  Future<bool> saveAppointment({
    required String companyId,
    required String operation,
    required Appointment appointment,
    required AppointmentAction action,
  }) async {
    emit(
      state.copyWith(
        status: AppointmentsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final previous = operation == 'update' && appointment.id.isNotEmpty
          ? await _loadAppointmentForAudit(companyId, appointment.id)
          : null;
      final savedAppointment = await _saveAppointmentUseCase(
        companyId: companyId,
        operation: operation,
        appointment: appointment,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: savedAppointment.updatedBy.isNotEmpty
              ? savedAppointment.updatedBy
              : savedAppointment.createdBy,
          action: _appointmentAuditAction(
            operation: operation,
            previous: previous,
            next: savedAppointment,
            fallbackAction: action,
          ),
          recordId: savedAppointment.id,
          recordTitle: _appointmentTitle(savedAppointment),
          recordSubtitle: _appointmentSubtitle(savedAppointment),
          metadata: _appointmentAuditMetadata(previous, savedAppointment),
        ),
      );
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: AppointmentsStatus.saved,
          lastAction: action,
          clearMessage: true,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'save', force: true));
      return true;
    } on AppointmentException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: error.message,
          lastAction: action,
        ),
      );
      return false;
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: action,
        ),
      );
      return false;
    }
  }

  Future<bool> changeStatus({
    required String companyId,
    required Appointment appointment,
    required AppointmentStatus status,
    required String updatedBy,
    AppointmentOutcome? outcome,
    String outcomeNotes = '',
    String cancellationReason = '',
  }) {
    final action = switch (status) {
      AppointmentStatus.completed => AppointmentAction.complete,
      AppointmentStatus.cancelled => AppointmentAction.cancel,
      AppointmentStatus.missed => AppointmentAction.markMissed,
      AppointmentStatus.rescheduled => AppointmentAction.reschedule,
      AppointmentStatus.scheduled => AppointmentAction.update,
    };
    return saveAppointment(
      companyId: companyId,
      operation: 'update',
      appointment: appointment.copyWith(
        status: status,
        updatedBy: updatedBy,
        outcome: outcome ?? appointment.outcome,
        outcomeNotes: outcomeNotes.trim().isEmpty
            ? appointment.outcomeNotes
            : outcomeNotes.trim(),
        cancellationReason: cancellationReason.trim().isEmpty
            ? appointment.cancellationReason
            : cancellationReason.trim(),
      ),
      action: action,
    );
  }

  Future<void> loadRelatedRecordOptions({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) async {
    if (type == AppointmentRelatedType.general) {
      emit(
        state.copyWith(
          clearRelatedRecords: true,
          clearRelatedRecordsMessage: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        relatedRecordsStatus: AppointmentRelatedRecordsStatus.loading,
        relatedRecordsType: type,
        relatedRecordOptions: const [],
        clearRelatedRecordsMessage: true,
      ),
    );
    try {
      final options = await _getRelatedRecordOptionsUseCase(
        companyId: companyId,
        type: type,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: options.isEmpty
              ? AppointmentRelatedRecordsStatus.empty
              : AppointmentRelatedRecordsStatus.loaded,
          relatedRecordsType: type,
          relatedRecordOptions: options,
          clearRelatedRecordsMessage: true,
        ),
      );
    } on AppointmentException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: AppointmentRelatedRecordsStatus.failure,
          relatedRecordsType: type,
          relatedRecordOptions: const [],
          relatedRecordsMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          relatedRecordsStatus: AppointmentRelatedRecordsStatus.failure,
          relatedRecordsType: type,
          relatedRecordOptions: const [],
          relatedRecordsMessage: AppErrorMessages.unknown,
        ),
      );
    }
  }

  void clearRelatedRecordOptions() {
    emit(
      state.copyWith(
        clearRelatedRecords: true,
        clearRelatedRecordsMessage: true,
      ),
    );
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  List<Appointment> _applyFilters(
    List<Appointment> appointments, {
    String? searchQuery,
    AppointmentStatus? statusFilter,
    AppointmentType? typeFilter,
    AppointmentDateFilter? dateFilter,
    DateTime? selectedDateFilter,
    String? assignedToFilter,
    bool overrideStatusFilter = false,
    bool overrideTypeFilter = false,
    bool overrideDateFilter = false,
    bool overrideSelectedDateFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStatus = overrideStatusFilter
        ? statusFilter
        : statusFilter ?? state.statusFilter;
    final selectedType =
        overrideTypeFilter ? typeFilter : typeFilter ?? state.typeFilter;
    final selectedDatePreset = overrideDateFilter
        ? dateFilter
        : dateFilter ?? state.dateFilter;
    final selectedSpecificDate = overrideSelectedDateFilter
        ? selectedDateFilter
        : selectedDateFilter ?? state.selectedDateFilter;
    final selectedAssignedTo =
        (assignedToFilter ?? state.assignedToFilter).trim();
    final now = DateTime.now();

    final filtered = appointments.where((appointment) {
      final matchesSearch = query.isEmpty ||
          appointment.title.toLowerCase().contains(query) ||
          appointment.relatedTitle.toLowerCase().contains(query) ||
          appointment.relatedSubtitle.toLowerCase().contains(query) ||
          appointment.assignedToName.toLowerCase().contains(query) ||
          appointment.assignedToEmail.toLowerCase().contains(query) ||
          appointment.location.toLowerCase().contains(query);
      final matchesStatus = selectedStatus == null ||
          _effectiveStatus(appointment, now) == selectedStatus;
      final matchesType =
          selectedType == null || appointment.type == selectedType;
      final matchesDate = selectedSpecificDate == null
          ? selectedDatePreset == null ||
              _matchesDateFilter(appointment, selectedDatePreset, now)
          : _matchesSelectedDate(appointment, selectedSpecificDate);
      final matchesAssignedTo = selectedAssignedTo.isEmpty ||
          appointment.assignedTo == selectedAssignedTo;
      return matchesSearch &&
          matchesStatus &&
          matchesType &&
          matchesDate &&
          matchesAssignedTo;
    }).toList()
      ..sort((a, b) => _compareAppointments(a, b, now));
    return filtered;
  }

  bool _matchesDateFilter(
    Appointment appointment,
    AppointmentDateFilter filter,
    DateTime now,
  ) {
    final scheduledAt = appointment.scheduledAt;
    if (scheduledAt == null) {
      return false;
    }
    final today = _dateOnly(now);
    final day = _dateOnly(scheduledAt.toLocal());
    final isMissed =
        DashboardTruthRules.isMissedAppointment(appointment, now);
    switch (filter) {
      case AppointmentDateFilter.today:
        return day == today;
      case AppointmentDateFilter.thisWeek:
        final weekEnd = today.add(const Duration(days: 7));
        return (day == today || day.isAfter(today)) && day.isBefore(weekEnd);
      case AppointmentDateFilter.upcoming:
        return !isMissed &&
            (appointment.status == AppointmentStatus.scheduled ||
                appointment.status == AppointmentStatus.rescheduled) &&
            (day == today || scheduledAt.isAfter(now));
      case AppointmentDateFilter.missed:
        return isMissed;
      case AppointmentDateFilter.feedbackNeeded:
        final endAt = (appointment.endAt ?? appointment.scheduledAt)?.toLocal();
        return appointment.status == AppointmentStatus.completed &&
            appointment.outcomeNotes.trim().isEmpty &&
            endAt != null &&
            endAt.isBefore(now);
      case AppointmentDateFilter.all:
        return true;
    }
  }

  bool _matchesSelectedDate(Appointment appointment, DateTime selectedDate) {
    final scheduledAt = appointment.scheduledAt;
    if (scheduledAt == null) {
      return false;
    }
    return _dateOnly(scheduledAt.toLocal()) == _dateOnly(selectedDate);
  }

  int _compareAppointments(Appointment a, Appointment b, DateTime now) {
    final groupCompare = _appointmentGroup(a, now).compareTo(
      _appointmentGroup(b, now),
    );
    if (groupCompare != 0) {
      return groupCompare;
    }
    final aDate = a.scheduledAt ?? DateTime(9999);
    final bDate = b.scheduledAt ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }

  int _appointmentGroup(Appointment appointment, DateTime now) {
    if (DashboardTruthRules.isMissedAppointment(appointment, now)) {
      return 0;
    }
    if (appointment.status == AppointmentStatus.scheduled ||
        appointment.status == AppointmentStatus.rescheduled) {
      return 1;
    }
    return 2;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  AppointmentStatus _effectiveStatus(Appointment appointment, DateTime now) {
    if (DashboardTruthRules.isMissedAppointment(appointment, now)) {
      return AppointmentStatus.missed;
    }
    return appointment.status;
  }

  bool _isAppointmentPastStart(Appointment appointment, DateTime now) {
    final scheduledAt = appointment.scheduledAt;
    return scheduledAt != null &&
        now.difference(scheduledAt.toLocal()).inSeconds >= 60;
  }

  bool _isOpenScheduledStatus(AppointmentStatus status) {
    return status == AppointmentStatus.scheduled ||
        status == AppointmentStatus.rescheduled;
  }

  Future<Appointment?> _loadAppointmentForAudit(
    String companyId,
    String appointmentId,
  ) async {
    try {
      return await _watchAppointmentUseCase(
        companyId: companyId,
        appointmentId: appointmentId,
      ).first.timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: '',
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.appointments,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block appointment workflows.
    }
  }

  AuditLogAction _appointmentAuditAction({
    required String operation,
    required Appointment? previous,
    required Appointment next,
    required AppointmentAction fallbackAction,
  }) {
    if (operation == 'create') {
      return AuditLogAction.create;
    }
    if (previous != null && previous.assignedTo != next.assignedTo) {
      return AuditLogAction.assign;
    }
    if (previous != null && previous.status != next.status) {
      return switch (next.status) {
        AppointmentStatus.completed => AuditLogAction.complete,
        AppointmentStatus.cancelled => AuditLogAction.cancel,
        AppointmentStatus.missed => AuditLogAction.statusChange,
        AppointmentStatus.rescheduled => AuditLogAction.statusChange,
        AppointmentStatus.scheduled => AuditLogAction.statusChange,
      };
    }
    return switch (fallbackAction) {
      AppointmentAction.create => AuditLogAction.create,
      AppointmentAction.complete => AuditLogAction.complete,
      AppointmentAction.cancel => AuditLogAction.cancel,
      AppointmentAction.markMissed || AppointmentAction.reschedule =>
        AuditLogAction.statusChange,
      AppointmentAction.update => AuditLogAction.update,
    };
  }

  Map<String, Object?> _appointmentAuditMetadata(
    Appointment? previous,
    Appointment next,
  ) {
    final changedFields = <Map<String, String>>[];
    void addChange(String field, String oldValue, String newValue) {
      if (oldValue == newValue) {
        return;
      }
      changedFields.add({
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
      });
    }

    if (previous != null) {
      addChange('status', previous.status.name, next.status.name);
      addChange('assignedTo', previous.assignedToName, next.assignedToName);
      addChange(
        'scheduledAt',
        previous.scheduledAt?.toIso8601String() ?? '',
        next.scheduledAt?.toIso8601String() ?? '',
      );
      addChange('location', previous.location, next.location);
    }

    return {
      'status': next.status.name,
      'assignedTo': next.assignedTo,
      'assignedToName': next.assignedToName,
      'teamId': next.teamId,
      'teamName': next.teamName,
      'managerId': next.managerId,
      'managerName': next.managerName,
      'scheduledAt': next.scheduledAt?.toIso8601String() ?? '',
      'relatedType': next.relatedType.name,
      'relatedId': next.relatedId,
      'relatedTitle': next.relatedTitle,
      if (changedFields.isNotEmpty) 'changedFields': changedFields,
    };
  }

  String _appointmentTitle(Appointment appointment) {
    final title = appointment.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final related = appointment.relatedTitle.trim();
    if (related.isNotEmpty) {
      return related;
    }
    return appointment.id;
  }

  String _appointmentSubtitle(Appointment appointment) {
    final parts = <String>[
      appointment.type.name,
      appointment.status.name,
      if (appointment.assignedToName.trim().isNotEmpty)
        appointment.assignedToName.trim(),
      if (appointment.scheduledAt != null)
        appointment.scheduledAt!.toLocal().toIso8601String(),
    ];
    return parts.join(' • ');
  }

  String _errorMessage(Object error) {
    if (error is AppointmentException) {
      return error.message;
    }
    return AppErrorMessages.unknown;
  }

  @override
  Future<void> close() {
    _isClosing = true;
    _appointmentsInitialLoadTimeout.cancel();
    _appointmentInitialLoadTimeout.cancel();
    _appointmentsSubscription?.cancel();
    _appointmentSubscription?.cancel();
    return super.close();
  }
}
