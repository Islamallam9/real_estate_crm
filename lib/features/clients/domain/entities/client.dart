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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
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
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

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
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];
}
