import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/user_membership.dart';

class UserMembershipModel extends UserMembership {
  const UserMembershipModel({
    required super.companyId,
    required super.companyName,
    required super.role,
    required super.isActive,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserMembershipModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Membership data was not found.');
    }

    return UserMembershipModel(
      companyId: data['companyId'] as String? ?? document.id,
      companyName: data['companyName'] as String? ?? '',
      role: RoleConstants.fromValue(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? false,
      status: data['status'] as String? ?? 'inactive',
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
    );
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
