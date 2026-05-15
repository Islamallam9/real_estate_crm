import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/company_metadata.dart';

class CompanyMetadataModel extends CompanyMetadata {
  const CompanyMetadataModel({
    required super.id,
    required super.name,
    required super.displayName,
    required super.status,
    required super.isActive,
    required super.createdAt,
    required super.createdBy,
    required super.updatedAt,
    required super.updatedBy,
    required super.settings,
    required super.limits,
    required super.features,
  });

  factory CompanyMetadataModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Company metadata was not found.');
    }

    return CompanyMetadataModel(
      id: data['id'] as String? ?? document.id,
      name: data['name'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      status: data['status'] as String? ?? 'inactive',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      updatedBy: data['updatedBy'] as String? ?? '',
      settings: _mapFromValue(data['settings']),
      limits: _mapFromValue(data['limits']),
      features: _mapFromValue(data['features']),
    );
  }
}

Map<String, Object?> _mapFromValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.from(value);
  }

  return const <String, Object?>{};
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
