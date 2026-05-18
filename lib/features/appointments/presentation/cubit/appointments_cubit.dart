import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/errors/appointment_exception.dart';
import '../../domain/usecases/get_appointment_related_record_options_usecase.dart';
import '../../domain/usecases/save_appointment_usecase.dart';
import '../../domain/usecases/watch_appointment_usecase.dart';
import '../../domain/usecases/watch_appointments_usecase.dart';
import 'appointments_state.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit({
    required WatchAppointmentsUseCase watchAppointmentsUseCase,
    required WatchAppointmentUseCase watchAppointmentUseCase,
    required SaveAppointmentUseCase saveAppointmentUseCase,
    required GetAppointmentRelatedRecordOptionsUseCase
        getRelatedRecordOptionsUseCase,
  })  : _watchAppointmentsUseCase = watchAppointmentsUseCase,
        _watchAppointmentUseCase = watchAppointmentUseCase,
        _saveAppointmentUseCase = saveAppointmentUseCase,
        _getRelatedRecordOptionsUseCase = getRelatedRecordOptionsUseCase,
        super(const AppointmentsState.initial());

  final WatchAppointmentsUseCase _watchAppointmentsUseCase;
  final WatchAppointmentUseCase _watchAppointmentUseCase;
  final SaveAppointmentUseCase _saveAppointmentUseCase;
  final GetAppointmentRelatedRecordOptionsUseCase
      _getRelatedRecordOptionsUseCase;

  StreamSubscription<List<Appointment>>? _appointmentsSubscription;
  StreamSubscription<Appointment?>? _appointmentSubscription;
  final InitialLoadTimeout _appointmentsInitialLoadTimeout =
      InitialLoadTimeout();
  final InitialLoadTimeout _appointmentInitialLoadTimeout =
      InitialLoadTimeout();

  void watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
  }) {
    emit(
      state.copyWith(
        status: AppointmentsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _appointmentsSubscription?.cancel();
    _appointmentsInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != AppointmentsStatus.loading ||
          state.appointments.isNotEmpty) {
        return;
      }
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
    ).listen(
      (appointments) {
        if (isClosed) {
          return;
        }
        _appointmentsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: appointments.isEmpty
                ? AppointmentsStatus.empty
                : AppointmentsStatus.loaded,
            appointments: appointments,
            filteredAppointments: _applyFilters(appointments),
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        _appointmentsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: AppointmentsStatus.failure,
            message: _errorMessage(error),
          ),
        );
      },
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
        filteredAppointments:
            _applyFilters(state.appointments, searchQuery: query),
      ),
    );
  }

  void setStatusFilter(AppointmentStatus? statusFilter) {
    emit(
      state.copyWith(
        statusFilter: statusFilter,
        clearStatusFilter: statusFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          statusFilter: statusFilter,
          overrideStatusFilter: true,
        ),
      ),
    );
  }

  void setTypeFilter(AppointmentType? typeFilter) {
    emit(
      state.copyWith(
        typeFilter: typeFilter,
        clearTypeFilter: typeFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          typeFilter: typeFilter,
          overrideTypeFilter: true,
        ),
      ),
    );
  }

  void setDateFilter(AppointmentDateFilter? dateFilter) {
    emit(
      state.copyWith(
        dateFilter: dateFilter,
        clearDateFilter: dateFilter == null,
        filteredAppointments: _applyFilters(
          state.appointments,
          dateFilter: dateFilter,
          overrideDateFilter: true,
        ),
      ),
    );
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        filteredAppointments:
            _applyFilters(state.appointments, assignedToFilter: assignedTo),
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: '',
        clearStatusFilter: true,
        clearTypeFilter: true,
        clearDateFilter: true,
        filteredAppointments: _applyFilters(
          state.appointments,
          searchQuery: '',
          statusFilter: null,
          typeFilter: null,
          dateFilter: null,
          assignedToFilter: '',
          overrideStatusFilter: true,
          overrideTypeFilter: true,
          overrideDateFilter: true,
        ),
      ),
    );
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
      await _saveAppointmentUseCase(
        companyId: companyId,
        operation: operation,
        appointment: appointment,
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
    String outcomeNotes = '',
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
        outcomeNotes: outcomeNotes.trim().isEmpty
            ? appointment.outcomeNotes
            : outcomeNotes.trim(),
      ),
      action: action,
    );
  }

  Future<void> loadRelatedRecordOptions({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
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
    String? assignedToFilter,
    bool overrideStatusFilter = false,
    bool overrideTypeFilter = false,
    bool overrideDateFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStatus = overrideStatusFilter
        ? statusFilter
        : statusFilter ?? state.statusFilter;
    final selectedType =
        overrideTypeFilter ? typeFilter : typeFilter ?? state.typeFilter;
    final selectedDateFilter = overrideDateFilter
        ? dateFilter
        : dateFilter ?? state.dateFilter;
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
      final matchesStatus =
          selectedStatus == null || appointment.status == selectedStatus;
      final matchesType =
          selectedType == null || appointment.type == selectedType;
      final matchesDate = selectedDateFilter == null ||
          _matchesDateFilter(appointment, selectedDateFilter, now);
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
    final endAt = appointment.endAt ?? scheduledAt;
    final isMissed = appointment.status == AppointmentStatus.missed ||
        (appointment.status == AppointmentStatus.scheduled &&
            endAt.isBefore(now));
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
      case AppointmentDateFilter.all:
        return true;
    }
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
    final endAt = appointment.endAt ?? appointment.scheduledAt;
    if (appointment.status == AppointmentStatus.missed ||
        (appointment.status == AppointmentStatus.scheduled &&
            endAt != null &&
            endAt.isBefore(now))) {
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

  String _errorMessage(Object error) {
    if (error is AppointmentException) {
      return error.message;
    }
    return AppErrorMessages.unknown;
  }

  @override
  Future<void> close() {
    _appointmentsInitialLoadTimeout.cancel();
    _appointmentInitialLoadTimeout.cancel();
    _appointmentsSubscription?.cancel();
    _appointmentSubscription?.cancel();
    return super.close();
  }
}
