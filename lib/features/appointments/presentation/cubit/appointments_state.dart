import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_related_record_option.dart';

enum AppointmentsStatus { initial, loading, loaded, empty, saving, saved, failure }

enum AppointmentRelatedRecordsStatus { initial, loading, loaded, empty, failure }

enum AppointmentAction {
  create,
  update,
  complete,
  cancel,
  markMissed,
  reschedule,
}

enum AppointmentDateFilter { today, thisWeek, upcoming, missed, feedbackNeeded, all }

enum AppointmentCalendarView { today, month, week, day }

class AppointmentsState extends Equatable {
  const AppointmentsState({
    required this.status,
    required this.appointments,
    required this.filteredAppointments,
    required this.selectedAppointment,
    required this.searchQuery,
    required this.statusFilter,
    required this.typeFilter,
    required this.dateFilter,
    required this.selectedDateFilter,
    required this.calendarView,
    required this.selectedCalendarDate,
    required this.assignedToFilter,
    required this.message,
    required this.lastAction,
    required this.relatedRecordsStatus,
    required this.relatedRecordsType,
    required this.relatedRecordOptions,
    required this.relatedRecordsMessage,
  });

  const AppointmentsState.initial()
      : status = AppointmentsStatus.initial,
        appointments = const [],
        filteredAppointments = const [],
        selectedAppointment = null,
        searchQuery = '',
        statusFilter = null,
        typeFilter = null,
        dateFilter = null,
        selectedDateFilter = null,
        calendarView = AppointmentCalendarView.today,
        selectedCalendarDate = null,
        assignedToFilter = '',
        message = null,
        lastAction = null,
        relatedRecordsStatus = AppointmentRelatedRecordsStatus.initial,
        relatedRecordsType = null,
        relatedRecordOptions = const [],
        relatedRecordsMessage = null;

  final AppointmentsStatus status;
  final List<Appointment> appointments;
  final List<Appointment> filteredAppointments;
  final Appointment? selectedAppointment;
  final String searchQuery;
  final AppointmentStatus? statusFilter;
  final AppointmentType? typeFilter;
  final AppointmentDateFilter? dateFilter;
  final DateTime? selectedDateFilter;
  final AppointmentCalendarView calendarView;
  final DateTime? selectedCalendarDate;
  final String assignedToFilter;
  final String? message;
  final AppointmentAction? lastAction;
  final AppointmentRelatedRecordsStatus relatedRecordsStatus;
  final AppointmentRelatedType? relatedRecordsType;
  final List<AppointmentRelatedRecordOption> relatedRecordOptions;
  final String? relatedRecordsMessage;

  AppointmentsState copyWith({
    AppointmentsStatus? status,
    List<Appointment>? appointments,
    List<Appointment>? filteredAppointments,
    Appointment? selectedAppointment,
    String? searchQuery,
    AppointmentStatus? statusFilter,
    AppointmentType? typeFilter,
    AppointmentDateFilter? dateFilter,
    DateTime? selectedDateFilter,
    AppointmentCalendarView? calendarView,
    DateTime? selectedCalendarDate,
    String? assignedToFilter,
    String? message,
    AppointmentAction? lastAction,
    AppointmentRelatedRecordsStatus? relatedRecordsStatus,
    AppointmentRelatedType? relatedRecordsType,
    List<AppointmentRelatedRecordOption>? relatedRecordOptions,
    String? relatedRecordsMessage,
    bool clearSelectedAppointment = false,
    bool clearMessage = false,
    bool clearLastAction = false,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
    bool clearDateFilter = false,
    bool clearSelectedDateFilter = false,
    bool clearSelectedCalendarDate = false,
    bool clearRelatedRecords = false,
    bool clearRelatedRecordsMessage = false,
  }) {
    return AppointmentsState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      filteredAppointments:
          filteredAppointments ?? this.filteredAppointments,
      selectedAppointment: clearSelectedAppointment
          ? null
          : selectedAppointment ?? this.selectedAppointment,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      typeFilter: clearTypeFilter ? null : typeFilter ?? this.typeFilter,
      dateFilter: clearDateFilter ? null : dateFilter ?? this.dateFilter,
      selectedDateFilter: clearSelectedDateFilter
          ? null
          : selectedDateFilter ?? this.selectedDateFilter,
      calendarView: calendarView ?? this.calendarView,
      selectedCalendarDate: clearSelectedCalendarDate
          ? null
          : selectedCalendarDate ?? this.selectedCalendarDate,
      assignedToFilter: assignedToFilter ?? this.assignedToFilter,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction ? null : lastAction ?? this.lastAction,
      relatedRecordsStatus: clearRelatedRecords
          ? AppointmentRelatedRecordsStatus.initial
          : relatedRecordsStatus ?? this.relatedRecordsStatus,
      relatedRecordsType: clearRelatedRecords
          ? null
          : relatedRecordsType ?? this.relatedRecordsType,
      relatedRecordOptions:
          clearRelatedRecords ? const [] : relatedRecordOptions ?? this.relatedRecordOptions,
      relatedRecordsMessage: clearRelatedRecords || clearRelatedRecordsMessage
          ? null
          : relatedRecordsMessage ?? this.relatedRecordsMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        appointments,
        filteredAppointments,
        selectedAppointment,
        searchQuery,
        statusFilter,
        typeFilter,
        dateFilter,
        selectedDateFilter,
        calendarView,
        selectedCalendarDate,
        assignedToFilter,
        message,
        lastAction,
        relatedRecordsStatus,
        relatedRecordsType,
        relatedRecordOptions,
        relatedRecordsMessage,
      ];
}
