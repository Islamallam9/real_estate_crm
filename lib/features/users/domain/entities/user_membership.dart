import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

class UserMembership extends Equatable {
  const UserMembership({
    required this.companyId,
    required this.companyName,
    required this.role,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String companyId;
  final String companyName;
  final UserRole role;
  final bool isActive;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUsable => isActive && (status == 'active' || status == 'trial');

  @override
  List<Object?> get props => [
    companyId,
    companyName,
    role,
    isActive,
    status,
    createdAt,
    updatedAt,
  ];
}
