import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/platform_payment_history.dart';

class PlatformPaymentHistoryModel extends PlatformPaymentHistory {
  const PlatformPaymentHistoryModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.action,
    required super.amount,
    required super.currency,
    required super.previousStatus,
    required super.newStatus,
    required super.notes,
    required super.actorUid,
    required super.actorName,
    required super.actorEmail,
    super.paymentDate,
    super.nextPaymentDueAt,
    super.createdAt,
  });

  factory PlatformPaymentHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return PlatformPaymentHistoryModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      action: data['action'] as String? ?? '',
      amount: _doubleFromValue(data['amount']),
      currency: data['currency'] as String? ?? '',
      paymentDate: _nullableDateTimeFromValue(data['paymentDate']),
      nextPaymentDueAt: _nullableDateTimeFromValue(data['nextPaymentDueAt']),
      previousStatus: data['previousStatus'] as String? ?? '',
      newStatus: data['newStatus'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      createdAt: _nullableDateTimeFromValue(data['createdAt']),
    );
  }
}

double _doubleFromValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
