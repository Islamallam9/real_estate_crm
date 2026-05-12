import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/deal.dart';

class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.companyId,
    required super.clientId,
    required super.clientName,
    required super.clientEmail,
    required super.clientPhone,
    required super.leadId,
    required super.leadName,
    required super.leadPhone,
    required super.propertyId,
    required super.propertyTitle,
    required super.propertyLocation,
    required super.assignedTo,
    required super.assignedToName,
    required super.assignedToEmail,
    required super.stage,
    required super.expectedValue,
    required super.commission,
    required super.closingDate,
    required super.lostReason,
    required super.notes,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.updatedBy,
  });

  factory DealModel.fromEntity(Deal deal) {
    return DealModel(
      id: deal.id,
      companyId: deal.companyId,
      clientId: deal.clientId,
      clientName: deal.clientName,
      clientEmail: deal.clientEmail,
      clientPhone: deal.clientPhone,
      leadId: deal.leadId,
      leadName: deal.leadName,
      leadPhone: deal.leadPhone,
      propertyId: deal.propertyId,
      propertyTitle: deal.propertyTitle,
      propertyLocation: deal.propertyLocation,
      assignedTo: deal.assignedTo,
      assignedToName: deal.assignedToName,
      assignedToEmail: deal.assignedToEmail,
      stage: deal.stage,
      expectedValue: deal.expectedValue,
      commission: deal.commission,
      closingDate: deal.closingDate,
      lostReason: deal.lostReason,
      notes: deal.notes,
      isActive: deal.isActive,
      createdAt: deal.createdAt,
      updatedAt: deal.updatedAt,
      createdBy: deal.createdBy,
      updatedBy: deal.updatedBy,
    );
  }

  factory DealModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Deal data was not found.');
    }

    return DealModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      clientEmail: data['clientEmail'] as String? ?? '',
      clientPhone: data['clientPhone'] as String? ?? '',
      leadId: data['leadId'] as String? ?? '',
      leadName: data['leadName'] as String? ?? '',
      leadPhone: data['leadPhone'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      propertyTitle: data['propertyTitle'] as String? ?? '',
      propertyLocation: data['propertyLocation'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      assignedToEmail: data['assignedToEmail'] as String? ?? '',
      stage: dealStageFromValue(data['stage'] as String? ?? 'new'),
      expectedValue: data['expectedValue'] as num? ?? 0,
      commission: data['commission'] as num? ?? 0,
      closingDate: _dateTimeFromValue(data['closingDate']),
      lostReason: data['lostReason'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'leadId': leadId,
      'leadName': leadName,
      'leadPhone': leadPhone,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyLocation': propertyLocation,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
      'stage': dealStageToValue(stage),
      'expectedValue': expectedValue,
      'commission': commission,
      'closingDate': closingDate == null ? null : Timestamp.fromDate(closingDate!),
      'lostReason': stage == DealStage.lost ? lostReason : '',
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}

DealStage dealStageFromValue(String value) {
  switch (value) {
    case 'qualified':
      return DealStage.qualified;
    case 'proposal':
      return DealStage.proposal;
    case 'negotiation':
      return DealStage.negotiation;
    case 'won':
      return DealStage.won;
    case 'lost':
      return DealStage.lost;
    case 'new':
    default:
      return DealStage.newDeal;
  }
}

String dealStageToValue(DealStage stage) {
  switch (stage) {
    case DealStage.newDeal:
      return 'new';
    case DealStage.qualified:
      return 'qualified';
    case DealStage.proposal:
      return 'proposal';
    case DealStage.negotiation:
      return 'negotiation';
    case DealStage.won:
      return 'won';
    case DealStage.lost:
      return 'lost';
  }
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
