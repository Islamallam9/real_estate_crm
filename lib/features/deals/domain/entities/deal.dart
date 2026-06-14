import 'package:equatable/equatable.dart';

enum DealStage { newDeal, qualified, proposal, negotiation, won, lost }

enum DealLostReason {
  budgetMismatch,
  locationMismatch,
  boughtElsewhere,
  notReady,
  noResponse,
  wrongNumber,
  lostToCompetitor,
  duplicate,
  other,
}

const List<DealLostReason> controlledDealLostReasons = DealLostReason.values;

DealLostReason? dealLostReasonFromValue(String value) {
  switch (value.trim()) {
    case 'budgetMismatch':
      return DealLostReason.budgetMismatch;
    case 'locationMismatch':
      return DealLostReason.locationMismatch;
    case 'boughtElsewhere':
      return DealLostReason.boughtElsewhere;
    case 'notReady':
      return DealLostReason.notReady;
    case 'noResponse':
      return DealLostReason.noResponse;
    case 'wrongNumber':
      return DealLostReason.wrongNumber;
    case 'lostToCompetitor':
      return DealLostReason.lostToCompetitor;
    case 'duplicate':
      return DealLostReason.duplicate;
    case 'other':
      return DealLostReason.other;
    default:
      return null;
  }
}

bool isControlledDealLostReasonValue(String value) {
  return dealLostReasonFromValue(value) != null;
}

String dealLostReasonToValue(DealLostReason reason) {
  switch (reason) {
    case DealLostReason.budgetMismatch:
      return 'budgetMismatch';
    case DealLostReason.locationMismatch:
      return 'locationMismatch';
    case DealLostReason.boughtElsewhere:
      return 'boughtElsewhere';
    case DealLostReason.notReady:
      return 'notReady';
    case DealLostReason.noResponse:
      return 'noResponse';
    case DealLostReason.wrongNumber:
      return 'wrongNumber';
    case DealLostReason.lostToCompetitor:
      return 'lostToCompetitor';
    case DealLostReason.duplicate:
      return 'duplicate';
    case DealLostReason.other:
      return 'other';
  }
}

class Deal extends Equatable {
  const Deal({
    required this.id,
    required this.companyId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.leadId,
    required this.leadName,
    required this.leadPhone,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyLocation,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedToEmail,
    this.teamId = '',
    this.teamName = '',
    this.managerId = '',
    this.managerName = '',
    required this.stage,
    required this.expectedValue,
    required this.commission,
    required this.closingDate,
    required this.lostReason,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy = '',
    this.archivedByName = '',
    this.archiveReason = '',
    this.restoredAt,
    this.restoredBy = '',
    this.restoredByName = '',
  });

  final String id;
  final String companyId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String leadId;
  final String leadName;
  final String leadPhone;
  final String propertyId;
  final String propertyTitle;
  final String propertyLocation;
  final String assignedTo;
  final String assignedToName;
  final String assignedToEmail;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
  final DealStage stage;
  final num expectedValue;
  final num commission;
  final DateTime? closingDate;
  final String lostReason;
  final String notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isArchived;
  final DateTime? archivedAt;
  final String archivedBy;
  final String archivedByName;
  final String archiveReason;
  final DateTime? restoredAt;
  final String restoredBy;
  final String restoredByName;

  Deal copyWith({
    String? id,
    String? companyId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? leadId,
    String? leadName,
    String? leadPhone,
    String? propertyId,
    String? propertyTitle,
    String? propertyLocation,
    String? assignedTo,
    String? assignedToName,
    String? assignedToEmail,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    DealStage? stage,
    num? expectedValue,
    num? commission,
    DateTime? closingDate,
    String? lostReason,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
    String? archivedByName,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredBy,
    String? restoredByName,
  }) {
    return Deal(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      leadPhone: leadPhone ?? this.leadPhone,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyLocation: propertyLocation ?? this.propertyLocation,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      stage: stage ?? this.stage,
      expectedValue: expectedValue ?? this.expectedValue,
      commission: commission ?? this.commission,
      closingDate: closingDate ?? this.closingDate,
      lostReason: lostReason ?? this.lostReason,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedByName: archivedByName ?? this.archivedByName,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredBy: restoredBy ?? this.restoredBy,
      restoredByName: restoredByName ?? this.restoredByName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    clientId,
    clientName,
    clientEmail,
    clientPhone,
    leadId,
    leadName,
    leadPhone,
    propertyId,
    propertyTitle,
    propertyLocation,
    assignedTo,
    assignedToName,
    assignedToEmail,
    teamId,
    teamName,
    managerId,
    managerName,
    stage,
    expectedValue,
    commission,
    closingDate,
    lostReason,
    notes,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    isArchived,
    archivedAt,
    archivedBy,
    archivedByName,
    archiveReason,
    restoredAt,
    restoredBy,
    restoredByName,
  ];
}
