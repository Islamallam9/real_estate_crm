import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.budgetMin,
    required this.budgetMax,
    required this.preferredLocation,
    required this.preferredPropertyType,
    required this.notes,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedToEmail,
    this.teamId = '',
    this.teamName = '',
    this.managerId = '',
    this.managerName = '',
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
  final String fullName;
  final String phone;
  final String email;
  final num? budgetMin;
  final num? budgetMax;
  final String preferredLocation;
  final String preferredPropertyType;
  final String notes;
  final String assignedTo;
  final String assignedToName;
  final String assignedToEmail;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
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

  @override
  List<Object?> get props => [
    id,
    companyId,
    fullName,
    phone,
    email,
    budgetMin,
    budgetMax,
    preferredLocation,
    preferredPropertyType,
    notes,
    assignedTo,
    assignedToName,
    assignedToEmail,
    teamId,
    teamName,
    managerId,
    managerName,
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
