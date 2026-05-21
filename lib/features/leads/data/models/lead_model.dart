import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/lead.dart';

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.companyId,
    required super.fullName,
    required super.phone,
    required super.email,
    required super.source,
    required super.status,
    required super.priority,
    required super.budgetMin,
    required super.budgetMax,
    required super.preferredLocation,
    required super.preferredPropertyType,
    required super.assignedTo,
    super.sourceDetails,
    super.assignedToName,
    super.teamId,
    super.teamName,
    super.managerId,
    super.managerName,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.updatedBy,
    super.lastContactAt,
    super.nextFollowUpAt,
    super.isArchived,
    super.archivedAt,
    super.archivedBy,
    super.archivedByName,
    super.archiveReason,
    super.restoredAt,
    super.restoredBy,
    super.restoredByName,
  });

  factory LeadModel.fromEntity(Lead lead) {
    return LeadModel(
      id: lead.id,
      companyId: lead.companyId,
      fullName: lead.fullName,
      phone: lead.phone,
      email: lead.email,
      source: lead.source,
      status: lead.status,
      priority: lead.priority,
      budgetMin: lead.budgetMin,
      budgetMax: lead.budgetMax,
      preferredLocation: lead.preferredLocation,
      preferredPropertyType: lead.preferredPropertyType,
      assignedTo: lead.assignedTo,
      sourceDetails: lead.sourceDetails,
      assignedToName: lead.assignedToName,
      teamId: lead.teamId,
      teamName: lead.teamName,
      managerId: lead.managerId,
      managerName: lead.managerName,
      notes: lead.notes,
      createdAt: lead.createdAt,
      updatedAt: lead.updatedAt,
      createdBy: lead.createdBy,
      updatedBy: lead.updatedBy,
      lastContactAt: lead.lastContactAt,
      nextFollowUpAt: lead.nextFollowUpAt,
      isArchived: lead.isArchived,
      archivedAt: lead.archivedAt,
      archivedBy: lead.archivedBy,
      archivedByName: lead.archivedByName,
      archiveReason: lead.archiveReason,
      restoredAt: lead.restoredAt,
      restoredBy: lead.restoredBy,
      restoredByName: lead.restoredByName,
    );
  }

  factory LeadModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Lead data was not found.');
    }

    return LeadModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      source: leadSourceFromValue(data['source'] as String? ?? 'other'),
      status: leadStatusFromValue(data['status'] as String? ?? 'new'),
      priority: leadPriorityFromValue(data['priority'] as String? ?? 'medium'),
      budgetMin: data['budgetMin'] as num? ?? 0,
      budgetMax: data['budgetMax'] as num? ?? 0,
      preferredLocation: data['preferredLocation'] as String? ?? '',
      preferredPropertyType: data['preferredPropertyType'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      sourceDetails: data['sourceDetails'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      lastContactAt: _nullableDateTimeFromValue(data['lastContactAt']),
      nextFollowUpAt: _nullableDateTimeFromValue(data['nextFollowUpAt']),
      isArchived: data['isArchived'] as bool? ?? false,
      archivedAt: _nullableDateTimeFromValue(data['archivedAt']),
      archivedBy: data['archivedBy'] as String?,
      archivedByName: data['archivedByName'] as String? ?? '',
      archiveReason: data['archiveReason'] as String? ?? '',
      restoredAt: _nullableDateTimeFromValue(data['restoredAt']),
      restoredBy: data['restoredBy'] as String?,
      restoredByName: data['restoredByName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'source': leadSourceToValue(source),
      'status': leadStatusToValue(status),
      'priority': leadPriorityToValue(priority),
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'preferredLocation': preferredLocation,
      'preferredPropertyType': preferredPropertyType,
      'assignedTo': assignedTo,
      'sourceDetails': sourceDetails,
      'assignedToName': assignedToName,
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'lastContactAt': _nullableTimestampFromDate(lastContactAt),
      'nextFollowUpAt': _nullableTimestampFromDate(nextFollowUpAt),
      'isArchived': isArchived,
      'archivedAt': archivedAt == null ? null : Timestamp.fromDate(archivedAt!),
      'archivedBy': archivedBy,
      'archivedByName': archivedByName,
      'archiveReason': archiveReason,
      'restoredAt': restoredAt == null ? null : Timestamp.fromDate(restoredAt!),
      'restoredBy': restoredBy,
      'restoredByName': restoredByName,
    };
  }
}

LeadSource leadSourceFromValue(String value) {
  switch (value) {
    case 'facebook':
      return LeadSource.facebook;
    case 'website':
      return LeadSource.website;
    case 'phoneCall':
      return LeadSource.phoneCall;
    case 'whatsapp':
      return LeadSource.whatsapp;
    case 'referral':
      return LeadSource.referral;
    case 'walkIn':
      return LeadSource.walkIn;
    case 'other':
      return LeadSource.other;
    default:
      return LeadSource.other;
  }
}

String leadSourceToValue(LeadSource source) {
  switch (source) {
    case LeadSource.facebook:
      return 'facebook';
    case LeadSource.website:
      return 'website';
    case LeadSource.phoneCall:
      return 'phoneCall';
    case LeadSource.whatsapp:
      return 'whatsapp';
    case LeadSource.referral:
      return 'referral';
    case LeadSource.walkIn:
      return 'walkIn';
    case LeadSource.other:
      return 'other';
  }
}

LeadStatus leadStatusFromValue(String value) {
  switch (value) {
    case 'new':
      return LeadStatus.newLead;
    case 'contacted':
      return LeadStatus.contacted;
    case 'interested':
      return LeadStatus.interested;
    case 'visitScheduled':
      return LeadStatus.visitScheduled;
    case 'negotiation':
      return LeadStatus.negotiation;
    case 'won':
      return LeadStatus.won;
    case 'lost':
      return LeadStatus.lost;
    default:
      return LeadStatus.newLead;
  }
}

String leadStatusToValue(LeadStatus status) {
  switch (status) {
    case LeadStatus.newLead:
      return 'new';
    case LeadStatus.contacted:
      return 'contacted';
    case LeadStatus.interested:
      return 'interested';
    case LeadStatus.visitScheduled:
      return 'visitScheduled';
    case LeadStatus.negotiation:
      return 'negotiation';
    case LeadStatus.won:
      return 'won';
    case LeadStatus.lost:
      return 'lost';
  }
}

LeadPriority leadPriorityFromValue(String value) {
  switch (value) {
    case 'low':
      return LeadPriority.low;
    case 'medium':
      return LeadPriority.medium;
    case 'high':
      return LeadPriority.high;
    default:
      return LeadPriority.medium;
  }
}

String leadPriorityToValue(LeadPriority priority) {
  switch (priority) {
    case LeadPriority.low:
      return 'low';
    case LeadPriority.medium:
      return 'medium';
    case LeadPriority.high:
      return 'high';
  }
}

DateTime _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }

  return _dateTimeFromValue(value);
}

Timestamp? _nullableTimestampFromDate(DateTime? value) {
  if (value == null) {
    return null;
  }

  return Timestamp.fromDate(value);
}
