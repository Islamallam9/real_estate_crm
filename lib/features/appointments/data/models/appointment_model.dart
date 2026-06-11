import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.companyId,
    required super.title,
    required super.type,
    required super.status,
    required super.scheduledAt,
    required super.endAt,
    required super.durationMinutes,
    required super.assignedTo,
    required super.assignedToName,
    required super.assignedToEmail,
    required super.teamId,
    required super.teamName,
    required super.managerId,
    required super.managerName,
    required super.relatedType,
    required super.relatedId,
    required super.relatedTitle,
    required super.relatedSubtitle,
    required super.location,
    required super.notes,
    super.outcome,
    required super.outcomeNotes,
    super.cancellationReason,
    required super.createdAt,
    required super.createdBy,
    required super.updatedAt,
    required super.updatedBy,
    super.completedAt,
    super.completedBy,
    super.cancelledAt,
    super.cancelledBy,
    super.missedAt,
    super.missedBy,
    super.rescheduledFrom,
    super.previousScheduledAt,
    super.previousEndAt,
  });

  factory AppointmentModel.fromEntity(Appointment appointment) {
    return AppointmentModel(
      id: appointment.id,
      companyId: appointment.companyId,
      title: appointment.title,
      type: appointment.type,
      status: appointment.status,
      scheduledAt: appointment.scheduledAt,
      endAt: appointment.endAt,
      durationMinutes: appointment.durationMinutes,
      assignedTo: appointment.assignedTo,
      assignedToName: appointment.assignedToName,
      assignedToEmail: appointment.assignedToEmail,
      teamId: appointment.teamId,
      teamName: appointment.teamName,
      managerId: appointment.managerId,
      managerName: appointment.managerName,
      relatedType: appointment.relatedType,
      relatedId: appointment.relatedId,
      relatedTitle: appointment.relatedTitle,
      relatedSubtitle: appointment.relatedSubtitle,
      location: appointment.location,
      notes: appointment.notes,
      outcome: appointment.outcome,
      outcomeNotes: appointment.outcomeNotes,
      cancellationReason: appointment.cancellationReason,
      createdAt: appointment.createdAt,
      createdBy: appointment.createdBy,
      updatedAt: appointment.updatedAt,
      updatedBy: appointment.updatedBy,
      completedAt: appointment.completedAt,
      completedBy: appointment.completedBy,
      cancelledAt: appointment.cancelledAt,
      cancelledBy: appointment.cancelledBy,
      missedAt: appointment.missedAt,
      missedBy: appointment.missedBy,
      rescheduledFrom: appointment.rescheduledFrom,
      previousScheduledAt: appointment.previousScheduledAt,
      previousEndAt: appointment.previousEndAt,
    );
  }

  factory AppointmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Appointment data was not found.');
    }
    final pathCompanyId = document.reference.parent.parent?.id ?? '';

    return AppointmentModel(
      id: _stringFromValue(data['id'], fallback: document.id),
      companyId: pathCompanyId.isNotEmpty
          ? pathCompanyId
          : _stringFromValue(data['companyId']),
      title: _stringFromValue(data['title']),
      type: _typeFromValue(data['type']),
      status: _statusFromValue(data['status']),
      scheduledAt: _dateTimeFromValue(data['scheduledAt']),
      endAt: _dateTimeFromValue(data['endAt']),
      durationMinutes: _intFromValue(data['durationMinutes'], fallback: 30),
      assignedTo: _stringFromValue(data['assignedTo']),
      assignedToName: _stringFromValue(data['assignedToName']),
      assignedToEmail: _stringFromValue(data['assignedToEmail']),
      teamId: _stringFromValue(data['teamId']),
      teamName: _stringFromValue(data['teamName']),
      managerId: _stringFromValue(data['managerId']),
      managerName: _stringFromValue(data['managerName']),
      relatedType: _relatedTypeFromValue(data['relatedType']),
      relatedId: _stringFromValue(data['relatedId']),
      relatedTitle: _stringFromValue(data['relatedTitle']),
      relatedSubtitle: _stringFromValue(data['relatedSubtitle']),
      location: _stringFromValue(data['location']),
      notes: _stringFromValue(data['notes']),
      outcome: _outcomeFromValue(data['outcome']),
      outcomeNotes: _stringFromValue(data['outcomeNotes']),
      cancellationReason: _stringFromValue(data['cancellationReason']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: _stringFromValue(data['createdBy']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      updatedBy: _stringFromValue(data['updatedBy']),
      completedAt: _dateTimeFromValue(data['completedAt']),
      completedBy: _stringFromValue(data['completedBy']),
      cancelledAt: _dateTimeFromValue(data['cancelledAt']),
      cancelledBy: _stringFromValue(data['cancelledBy']),
      missedAt: _dateTimeFromValue(data['missedAt']),
      missedBy: _stringFromValue(data['missedBy']),
      rescheduledFrom: _dateTimeFromValue(data['rescheduledFrom']),
      previousScheduledAt: _dateTimeFromValue(data['previousScheduledAt']),
      previousEndAt: _dateTimeFromValue(data['previousEndAt']),
    );
  }

  Map<String, Object?> toCallablePayload() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'type': type.name,
      'status': status.name,
      'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      'endAt': endAt?.toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      'assignedTo': assignedTo,
      'relatedType': relatedType.name,
      'relatedId': relatedId,
      'relatedTitle': relatedTitle,
      'relatedSubtitle': relatedSubtitle,
      'location': location,
      'notes': notes,
      'outcome': outcome?.name ?? '',
      'outcomeNotes': outcomeNotes,
      'cancellationReason': cancellationReason,
      'updatedBy': updatedBy,
    };
  }
}


String _stringFromValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : value;
  }
  return value.toString();
}

int _intFromValue(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

AppointmentType _typeFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: AppointmentType.other.name,
  );
  return AppointmentType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => AppointmentType.other,
  );
}

AppointmentStatus _statusFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: AppointmentStatus.scheduled.name,
  );
  return AppointmentStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => AppointmentStatus.scheduled,
  );
}

AppointmentOutcome? _outcomeFromValue(Object? value) {
  final name = _stringFromValue(value).trim();
  if (name.isEmpty) {
    return null;
  }
  return AppointmentOutcome.values.firstWhere(
    (outcome) => outcome.name == name,
    orElse: () => AppointmentOutcome.other,
  );
}

AppointmentRelatedType _relatedTypeFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: AppointmentRelatedType.general.name,
  );
  return AppointmentRelatedType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => AppointmentRelatedType.general,
  );
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
