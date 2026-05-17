import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/deal.dart';
import '../models/deal_model.dart';

class DealException implements Exception {
  const DealException(this.message);

  final String message;
}

abstract interface class DealsRemoteDataSource {
  Stream<List<DealModel>> watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    int limit,
  });

  Future<DealModel> createDeal({
    required String companyId,
    required DealModel deal,
  });

  Future<DealModel> updateDeal({
    required String companyId,
    required DealModel deal,
  });

  Future<void> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  });

  Future<void> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  });
}

class FirestoreDealsRemoteDataSource implements DealsRemoteDataSource {
  FirestoreDealsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DealModel>> watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    int limit = 40,
  }) {
    Query<Map<String, dynamic>> query = _dealsCollection(companyId).where(
      'isActive',
      isEqualTo: true,
    );

    if (role == UserRole.manager) {
      query = query.where('managerId', isEqualTo: currentUserId);
    } else if (role == UserRole.salesAgent ||
        role == UserRole.marketing ||
        role == UserRole.viewer) {
      query = query.where('assignedTo', isEqualTo: currentUserId);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final deals = snapshot.docs.map((document) {
        final deal = DealModel.fromFirestore(document);
        _ensureSameCompany(companyId: companyId, deal: deal);
        return deal;
      }).toList();

      deals.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return deals;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw DealException(_mapFirestoreError(error));
      }
      throw const DealException(AppErrorMessages.unknown);
    });
  }

  @override
  Future<DealModel> createDeal({
    required String companyId,
    required DealModel deal,
  }) async {
    _ensureSameCompany(companyId: companyId, deal: deal);
    _validateLostReason(deal.stage, deal.lostReason);
    try {
      final collection = _dealsCollection(companyId);
      final document = deal.id.isEmpty ? collection.doc() : collection.doc(deal.id);
      final now = DateTime.now();
      final dealToSave = DealModel(
        id: document.id,
        companyId: companyId,
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
        teamId: deal.teamId,
        teamName: deal.teamName,
        managerId: deal.managerId,
        managerName: deal.managerName,
        stage: deal.stage,
        expectedValue: deal.expectedValue,
        commission: deal.commission,
        closingDate: deal.closingDate,
        lostReason: deal.stage == DealStage.lost ? deal.lostReason : '',
        notes: deal.notes,
        isActive: true,
        createdAt: deal.createdAt ?? now,
        updatedAt: now,
        createdBy: deal.createdBy,
        updatedBy: deal.updatedBy,
      );
      await document.set(dealToSave.toFirestore());
      return dealToSave;
    } on DealException {
      rethrow;
    } on FirebaseException catch (error) {
      throw DealException(_mapFirestoreError(error));
    } catch (_) {
      throw const DealException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<DealModel> updateDeal({
    required String companyId,
    required DealModel deal,
  }) async {
    _ensureSameCompany(companyId: companyId, deal: deal);
    _validateLostReason(deal.stage, deal.lostReason);
    try {
      final document = _dealsCollection(companyId).doc(deal.id);
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const DealException(AppErrorMessages.notFound);
      }
      final existingDeal = DealModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, deal: existingDeal);
      await document.update({
        'clientId': deal.clientId,
        'clientName': deal.clientName,
        'clientEmail': deal.clientEmail,
        'clientPhone': deal.clientPhone,
        'leadId': deal.leadId,
        'leadName': deal.leadName,
        'leadPhone': deal.leadPhone,
        'propertyId': deal.propertyId,
        'propertyTitle': deal.propertyTitle,
        'propertyLocation': deal.propertyLocation,
        'assignedTo': deal.assignedTo,
        'assignedToName': deal.assignedToName,
        'assignedToEmail': deal.assignedToEmail,
        'teamId': deal.teamId,
        'teamName': deal.teamName,
        'managerId': deal.managerId,
        'managerName': deal.managerName,
        'stage': dealStageToValue(deal.stage),
        'expectedValue': deal.expectedValue,
        'commission': deal.commission,
        'closingDate': deal.closingDate == null
            ? null
            : Timestamp.fromDate(deal.closingDate!),
        'lostReason': deal.stage == DealStage.lost ? deal.lostReason : '',
        'notes': deal.notes,
        'updatedAt': Timestamp.now(),
        'updatedBy': deal.updatedBy,
      });
      final updatedSnapshot = await document.get();
      return DealModel.fromFirestore(updatedSnapshot);
    } on DealException {
      rethrow;
    } on FirebaseException catch (error) {
      throw DealException(_mapFirestoreError(error));
    } catch (_) {
      throw const DealException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  }) async {
    _validateLostReason(stage, lostReason);
    try {
      final document = _dealsCollection(companyId).doc(dealId);
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const DealException(AppErrorMessages.notFound);
      }
      final existingDeal = DealModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, deal: existingDeal);
      await document.update({
        'stage': dealStageToValue(stage),
        'lostReason': stage == DealStage.lost ? lostReason.trim() : '',
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedBy,
      });
    } on DealException {
      rethrow;
    } on FirebaseException catch (error) {
      throw DealException(_mapFirestoreError(error));
    } catch (_) {
      throw const DealException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) async {
    try {
      final document = _dealsCollection(companyId).doc(dealId);
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const DealException(AppErrorMessages.notFound);
      }
      final existingDeal = DealModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, deal: existingDeal);
      await document.update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedBy,
      });
    } on DealException {
      rethrow;
    } on FirebaseException catch (error) {
      throw DealException(_mapFirestoreError(error));
    } catch (_) {
      throw const DealException(AppErrorMessages.unknown);
    }
  }

  CollectionReference<Map<String, dynamic>> _dealsCollection(String companyId) {
    return _firestore.collection(FirebasePaths.companyDeals(companyId));
  }
}

void _validateLostReason(DealStage stage, String lostReason) {
  if (stage == DealStage.lost && lostReason.trim().isEmpty) {
    throw const DealException('lostReasonRequired');
  }
}

void _ensureSameCompany({required String companyId, required DealModel deal}) {
  if (companyId.isEmpty || deal.companyId != companyId) {
    throw const DealException(AppErrorMessages.permissionDenied);
  }
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    default:
      return AppErrorMessages.unknown;
  }
}
