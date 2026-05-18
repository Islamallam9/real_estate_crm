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
    required super.outcomeNotes,
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
      outcomeNotes: appointment.outcomeNotes,
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
    return AppointmentModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      type: _typeFromValue(data['type']),
      status: _statusFromValue(data['status']),
      scheduledAt: _dateTimeFromValue(data['scheduledAt']),
      endAt: _dateTimeFromValue(data['endAt']),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      assignedToEmail: data['assignedToEmail'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      relatedType: _relatedTypeFromValue(data['relatedType']),
      relatedId: data['relatedId'] as String? ?? '',
      relatedTitle: data['relatedTitle'] as String? ?? '',
      relatedSubtitle: data['relatedSubtitle'] as String? ?? '',
      location: data['location'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      outcomeNotes: data['outcomeNotes'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      updatedBy: data['updatedBy'] as String? ?? '',
      completedAt: _dateTimeFromValue(data['completedAt']),
      completedBy: data['completedBy'] as String? ?? '',
      cancelledAt: _dateTimeFromValue(data['cancelledAt']),
      cancelledBy: data['cancelledBy'] as String? ?? '',
      missedAt: _dateTimeFromValue(data['missedAt']),
      missedBy: data['missedBy'] as String? ?? '',
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
      'outcomeNotes': outcomeNotes,
      'updatedBy': updatedBy,
    };
  }
}

AppointmentType _typeFromValue(Object? value) {
  final name = value as String? ?? AppointmentType.other.name;
  return AppointmentType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => AppointmentType.other,
  );
}

AppointmentStatus _statusFromValue(Object? value) {
  final name = value as String? ?? AppointmentStatus.scheduled.name;
  return AppointmentStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => AppointmentStatus.scheduled,
  );
}

AppointmentRelatedType _relatedTypeFromValue(Object? value) {
  final name = value as String? ?? AppointmentRelatedType.general.name;
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
