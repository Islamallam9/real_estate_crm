import 'package:equatable/equatable.dart';

enum LeadSource {
  facebook,
  website,
  phoneCall,
  whatsapp,
  referral,
  walkIn,
  other,
}

enum LeadStatus {
  newLead,
  contacted,
  interested,
  visitScheduled,
  negotiation,
  won,
  lost,
}

enum LeadPriority { low, medium, high }

class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.source,
    required this.status,
    required this.priority,
    required this.budgetMin,
    required this.budgetMax,
    required this.preferredLocation,
    required this.preferredPropertyType,
    required this.assignedTo,
    this.sourceDetails = '',
    this.assignedToName = '',
    this.teamId = '',
    this.teamName = '',
    this.managerId = '',
    this.managerName = '',
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.lastContactAt,
    this.nextFollowUpAt,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
  });

  final String id;
  final String companyId;
  final String fullName;
  final String phone;
  final String email;
  final LeadSource source;
  final LeadStatus status;
  final LeadPriority priority;
  final num budgetMin;
  final num budgetMax;
  final String preferredLocation;
  final String preferredPropertyType;
  final String assignedTo;
  final String sourceDetails;
  final String assignedToName;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final DateTime? lastContactAt;
  final DateTime? nextFollowUpAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedBy;

  Lead copyWith({
    String? id,
    String? companyId,
    String? fullName,
    String? phone,
    String? email,
    LeadSource? source,
    LeadStatus? status,
    LeadPriority? priority,
    num? budgetMin,
    num? budgetMax,
    String? preferredLocation,
    String? preferredPropertyType,
    String? assignedTo,
    String? sourceDetails,
    String? assignedToName,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? lastContactAt,
    DateTime? nextFollowUpAt,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
  }) {
    return Lead(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      source: source ?? this.source,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      preferredPropertyType:
          preferredPropertyType ?? this.preferredPropertyType,
      assignedTo: assignedTo ?? this.assignedTo,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      assignedToName: assignedToName ?? this.assignedToName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    fullName,
    phone,
    email,
    source,
    status,
    priority,
    budgetMin,
    budgetMax,
    preferredLocation,
    preferredPropertyType,
    assignedTo,
    sourceDetails,
    assignedToName,
    teamId,
    teamName,
    managerId,
    managerName,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    lastContactAt,
    nextFollowUpAt,
    isArchived,
    archivedAt,
    archivedBy,
  ];
}
