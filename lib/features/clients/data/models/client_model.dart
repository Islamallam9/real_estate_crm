import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.companyId,
    required super.fullName,
    required super.phone,
    required super.email,
    required super.budgetMin,
    required super.budgetMax,
    required super.preferredLocation,
    required super.preferredPropertyType,
    required super.notes,
    required super.assignedTo,
    required super.assignedToName,
    required super.assignedToEmail,
    super.teamId,
    super.teamName,
    super.managerId,
    super.managerName,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.updatedBy,
  });

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      companyId: client.companyId,
      fullName: client.fullName,
      phone: client.phone,
      email: client.email,
      budgetMin: client.budgetMin,
      budgetMax: client.budgetMax,
      preferredLocation: client.preferredLocation,
      preferredPropertyType: client.preferredPropertyType,
      notes: client.notes,
      assignedTo: client.assignedTo,
      assignedToName: client.assignedToName,
      assignedToEmail: client.assignedToEmail,
      teamId: client.teamId,
      teamName: client.teamName,
      managerId: client.managerId,
      managerName: client.managerName,
      isActive: client.isActive,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
      createdBy: client.createdBy,
      updatedBy: client.updatedBy,
    );
  }

  factory ClientModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Client data was not found.');
    }

    return ClientModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      budgetMin: data['budgetMin'] as num?,
      budgetMax: data['budgetMax'] as num?,
      preferredLocation: data['preferredLocation'] as String? ?? '',
      preferredPropertyType: data['preferredPropertyType'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      assignedToEmail: data['assignedToEmail'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'preferredLocation': preferredLocation,
      'preferredPropertyType': preferredPropertyType,
      'notes': notes,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
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
