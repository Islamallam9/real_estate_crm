import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.companyId,
    required super.name,
    required super.description,
    required super.managerId,
    required super.managerName,
    required super.managerEmail,
    required super.isActive,
    required super.memberCount,
    required super.createdAt,
    required super.createdBy,
    required super.updatedAt,
    required super.updatedBy,
  });

  factory TeamModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Team data was not found.');
    }

    return TeamModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      managerEmail: data['managerEmail'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      memberCount: _intFromValue(data['memberCount']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }
}

int _intFromValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
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
