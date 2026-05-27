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
    super.trialStartedAt,
    super.trialEndsAt,
    super.trialDurationValue,
    super.trialDurationUnit,
    super.paymentStatus,
    super.nextPaymentDueAt,
    super.lastPaymentAt,
    super.paymentAmount,
    super.paymentCurrency,
    super.paymentCycle,
    super.paymentNotes,
    super.gracePeriodEndsAt,
    super.suspendedAt,
    super.suspendedReason,
    super.paymentUpdatedAt,
    super.paymentUpdatedBy,
    super.paymentReminderState = const <String, Object?>{},
    super.storageUsedBytes,
    super.storageUsageUpdatedAt,
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
      trialStartedAt: _nullableDateTimeFromValue(data['trialStartedAt']),
      trialEndsAt: _nullableDateTimeFromValue(data['trialEndsAt']),
      trialDurationValue: _intFromValue(data['trialDurationValue']),
      trialDurationUnit: data['trialDurationUnit'] as String?,
      paymentStatus: data['paymentStatus'] as String?,
      nextPaymentDueAt: _nullableDateTimeFromValue(data['nextPaymentDueAt']),
      lastPaymentAt: _nullableDateTimeFromValue(data['lastPaymentAt']),
      paymentAmount: _doubleFromValue(data['paymentAmount']),
      paymentCurrency: data['paymentCurrency'] as String?,
      paymentCycle: data['paymentCycle'] as String?,
      paymentNotes: data['paymentNotes'] as String?,
      gracePeriodEndsAt: _nullableDateTimeFromValue(data['gracePeriodEndsAt']),
      suspendedAt: _nullableDateTimeFromValue(data['suspendedAt']),
      suspendedReason: data['suspendedReason'] as String?,
      paymentUpdatedAt: _nullableDateTimeFromValue(data['paymentUpdatedAt']),
      paymentUpdatedBy: data['paymentUpdatedBy'] as String?,
      paymentReminderState: _mapFromValue(data['paymentReminderState']),
      storageUsedBytes: _intFromValue(data['storageUsedBytes']),
      storageUsageUpdatedAt: _nullableDateTimeFromValue(
        data['storageUsageUpdatedAt'],
      ),
    );
  }
}

double? _doubleFromValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? _intFromValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _dateTimeFromValue(value);
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
