import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

class PlatformCompanyUser extends Equatable {
  const PlatformCompanyUser({
    required this.uid,
    required this.companyId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String uid;
  final String companyId;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  @override
  List<Object?> get props => [
    uid,
    companyId,
    fullName,
    email,
    phone,
    role,
    isActive,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  ];
}
