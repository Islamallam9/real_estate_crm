import 'package:equatable/equatable.dart';

class CompanyMetadata extends Equatable {
  const CompanyMetadata({
    required this.id,
    required this.name,
    required this.displayName,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.settings,
    required this.limits,
    required this.features,
    this.trialStartedAt,
    this.trialEndsAt,
    this.trialDurationValue,
    this.trialDurationUnit,
    this.paymentStatus,
    this.nextPaymentDueAt,
    this.lastPaymentAt,
    this.paymentAmount,
    this.paymentCurrency,
    this.paymentCycle,
    this.paymentNotes,
    this.gracePeriodEndsAt,
    this.suspendedAt,
    this.suspendedReason,
    this.paymentUpdatedAt,
    this.paymentUpdatedBy,
    this.paymentReminderState = const {},
    this.storageUsedBytes,
    this.storageUsageUpdatedAt,
  });

  final String id;
  final String name;
  final String displayName;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final Map<String, Object?> settings;
  final Map<String, Object?> limits;
  final Map<String, Object?> features;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final int? trialDurationValue;
  final String? trialDurationUnit;
  final String? paymentStatus;
  final DateTime? nextPaymentDueAt;
  final DateTime? lastPaymentAt;
  final double? paymentAmount;
  final String? paymentCurrency;
  final String? paymentCycle;
  final String? paymentNotes;
  final DateTime? gracePeriodEndsAt;
  final DateTime? suspendedAt;
  final String? suspendedReason;
  final DateTime? paymentUpdatedAt;
  final String? paymentUpdatedBy;
  final Map<String, Object?> paymentReminderState;
  final int? storageUsedBytes;
  final DateTime? storageUsageUpdatedAt;

  bool get isTrial => status == 'trial';

  bool get isTrialExpired => status == 'trialExpired';

  bool get isUsable => isActive && (status == 'active' || isTrial);

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    status,
    isActive,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    settings,
    limits,
    features,
    trialStartedAt,
    trialEndsAt,
    trialDurationValue,
    trialDurationUnit,
    paymentStatus,
    nextPaymentDueAt,
    lastPaymentAt,
    paymentAmount,
    paymentCurrency,
    paymentCycle,
    paymentNotes,
    gracePeriodEndsAt,
    suspendedAt,
    suspendedReason,
    paymentUpdatedAt,
    paymentUpdatedBy,
    paymentReminderState,
    storageUsedBytes,
    storageUsageUpdatedAt,
  ];
}
