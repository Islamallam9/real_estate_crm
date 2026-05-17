import 'package:equatable/equatable.dart';

class Team extends Equatable {
  const Team({
    required this.id,
    required this.companyId,
    required this.name,
    required this.description,
    required this.managerId,
    required this.managerName,
    required this.managerEmail,
    required this.isActive,
    required this.memberCount,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String id;
  final String companyId;
  final String name;
  final String description;
  final String managerId;
  final String managerName;
  final String managerEmail;
  final bool isActive;
  final int memberCount;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  @override
  List<Object?> get props => [
    id,
    companyId,
    name,
    description,
    managerId,
    managerName,
    managerEmail,
    isActive,
    memberCount,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  ];
}
