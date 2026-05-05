import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.companyId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
  });

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('User profile data was not found.');
    }

    return UserProfileModel(
      uid: data['uid'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: RoleConstants.fromValue(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'companyId': companyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': RoleConstants.toValue(role),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
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
