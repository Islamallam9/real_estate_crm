import 'package:equatable/equatable.dart';

enum AppointmentType {
  call,
  meeting,
  propertyViewing,
  siteVisit,
  contractMeeting,
  reservationMeeting,
  followUp,
  other,
}

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
  missed,
  rescheduled,
}

enum AppointmentOutcome {
  successfulMeeting,
  noAnswer,
  clientPostponed,
  clientNotInterested,
  followUpNeeded,
  dealOpportunity,
  pendingDecision,
  other,
}

enum AppointmentRelatedType { lead, client, property, deal, general }

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.companyId,
    required this.title,
    required this.type,
    required this.status,
    required this.scheduledAt,
    required this.endAt,
    required this.durationMinutes,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedToEmail,
    required this.teamId,
    required this.teamName,
    required this.managerId,
    required this.managerName,
    required this.relatedType,
    required this.relatedId,
    required this.relatedTitle,
    required this.relatedSubtitle,
    required this.location,
    required this.notes,
    this.outcome,
    required this.outcomeNotes,
    this.cancellationReason = '',
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.completedAt,
    this.completedBy = '',
    this.cancelledAt,
    this.cancelledBy = '',
    this.missedAt,
    this.missedBy = '',
    this.rescheduledFrom,
    this.previousScheduledAt,
    this.previousEndAt,
  });

  final String id;
  final String companyId;
  final String title;
  final AppointmentType type;
  final AppointmentStatus status;
  final DateTime? scheduledAt;
  final DateTime? endAt;
  final int durationMinutes;
  final String assignedTo;
  final String assignedToName;
  final String assignedToEmail;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
  final AppointmentRelatedType relatedType;
  final String relatedId;
  final String relatedTitle;
  final String relatedSubtitle;
  final String location;
  final String notes;
  final AppointmentOutcome? outcome;
  final String outcomeNotes;
  final String cancellationReason;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;
  final DateTime? completedAt;
  final String completedBy;
  final DateTime? cancelledAt;
  final String cancelledBy;
  final DateTime? missedAt;
  final String missedBy;
  final DateTime? rescheduledFrom;
  final DateTime? previousScheduledAt;
  final DateTime? previousEndAt;

  Appointment copyWith({
    String? id,
    String? companyId,
    String? title,
    AppointmentType? type,
    AppointmentStatus? status,
    DateTime? scheduledAt,
    DateTime? endAt,
    int? durationMinutes,
    String? assignedTo,
    String? assignedToName,
    String? assignedToEmail,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    AppointmentRelatedType? relatedType,
    String? relatedId,
    String? relatedTitle,
    String? relatedSubtitle,
    String? location,
    String? notes,
    AppointmentOutcome? outcome,
    String? outcomeNotes,
    String? cancellationReason,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? completedAt,
    String? completedBy,
    DateTime? cancelledAt,
    String? cancelledBy,
    DateTime? missedAt,
    String? missedBy,
    DateTime? rescheduledFrom,
    DateTime? previousScheduledAt,
    DateTime? previousEndAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      endAt: endAt ?? this.endAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      relatedTitle: relatedTitle ?? this.relatedTitle,
      relatedSubtitle: relatedSubtitle ?? this.relatedSubtitle,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      outcome: outcome ?? this.outcome,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      missedAt: missedAt ?? this.missedAt,
      missedBy: missedBy ?? this.missedBy,
      rescheduledFrom: rescheduledFrom ?? this.rescheduledFrom,
      previousScheduledAt: previousScheduledAt ?? this.previousScheduledAt,
      previousEndAt: previousEndAt ?? this.previousEndAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        title,
        type,
        status,
        scheduledAt,
        endAt,
        durationMinutes,
        assignedTo,
        assignedToName,
        assignedToEmail,
        teamId,
        teamName,
        managerId,
        managerName,
        relatedType,
        relatedId,
        relatedTitle,
        relatedSubtitle,
        location,
        notes,
        outcome,
        outcomeNotes,
        cancellationReason,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        completedAt,
        completedBy,
        cancelledAt,
        cancelledBy,
        missedAt,
        missedBy,
        rescheduledFrom,
        previousScheduledAt,
        previousEndAt,
      ];
}
