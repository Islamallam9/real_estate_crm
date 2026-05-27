import 'package:equatable/equatable.dart';

class PlatformPaymentHistory extends Equatable {
  const PlatformPaymentHistory({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.action,
    required this.amount,
    required this.currency,
    required this.previousStatus,
    required this.newStatus,
    required this.notes,
    required this.actorUid,
    required this.actorName,
    required this.actorEmail,
    this.paymentDate,
    this.nextPaymentDueAt,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String action;
  final double amount;
  final String currency;
  final DateTime? paymentDate;
  final DateTime? nextPaymentDueAt;
  final String previousStatus;
  final String newStatus;
  final String notes;
  final String actorUid;
  final String actorName;
  final String actorEmail;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        action,
        amount,
        currency,
        paymentDate,
        nextPaymentDueAt,
        previousStatus,
        newStatus,
        notes,
        actorUid,
        actorName,
        actorEmail,
        createdAt,
      ];
}
