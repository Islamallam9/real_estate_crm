import 'package:equatable/equatable.dart';

enum DealStage { newDeal, qualified, proposal, negotiation, won, lost }

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
  ];
}
