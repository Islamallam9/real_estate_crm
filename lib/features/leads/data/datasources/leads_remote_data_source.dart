import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/lead_exception.dart';
import '../models/lead_model.dart';

abstract interface class LeadsRemoteDataSource {
  Future<LeadModel> createLead({
    required String companyId,
    required LeadModel lead,
  });

  Future<bool> hasDuplicateLead({
    required String companyId,
    required String phone,
    required String email,
    String? excludeLeadId,
  });

  Future<LeadModel> updateLead({
    required String companyId,
    required LeadModel lead,
  });

  Future<LeadModel> getLeadById({
    required String companyId,
    required String leadId,
  });

  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
  });

  Stream<List<LeadModel>> watchLeads({
    required String companyId,
    String? assignedTo,
    int limit,
  });
}

class FirestoreLeadsRemoteDataSource implements LeadsRemoteDataSource {
  FirestoreLeadsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<bool> hasDuplicateLead({
    required String companyId,
    required String phone,
    required String email,
    String? excludeLeadId,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedPhone.isEmpty && normalizedEmail.isEmpty) {
      return false;
    }

    try {
      final snapshot = await _leadsCollection(companyId).get();
      for (final document in snapshot.docs) {
        if (excludeLeadId != null && document.id == excludeLeadId) {
          continue;
        }
        final lead = LeadModel.fromFirestore(document);
        if (excludeLeadId != null && lead.id == excludeLeadId) {
          continue;
        }
        _ensureSameCompany(companyId: companyId, lead: lead);
        if (lead.isArchived) {
          continue;
        }

        final hasSamePhone =
            normalizedPhone.isNotEmpty &&
            _normalizePhone(lead.phone) == normalizedPhone;
        final hasSameEmail =
            normalizedEmail.isNotEmpty &&
            _normalizeEmail(lead.email) == normalizedEmail;
        if (hasSamePhone || hasSameEmail) {
          return true;
        }
      }
      return false;
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to check duplicate lead.');
    }
  }

  @override
  Future<LeadModel> createLead({
    required String companyId,
    required LeadModel lead,
  }) async {
    _ensureSameCompany(companyId: companyId, lead: lead);
    try {
      final collection = _leadsCollection(companyId);
      final document = lead.id.isEmpty
          ? collection.doc()
          : collection.doc(lead.id);
      final leadToSave = LeadModel.fromEntity(
        lead.copyWith(id: document.id, companyId: companyId, isArchived: false),
      );
      await document.set(leadToSave.toFirestore());
      return leadToSave;
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to create lead. Please try again.');
    }
  }

  @override
  Future<LeadModel> updateLead({
    required String companyId,
    required LeadModel lead,
  }) async {
    _ensureSameCompany(companyId: companyId, lead: lead);
    try {
      final document = _leadsCollection(companyId).doc(lead.id);
      await document.update(lead.toFirestore());
      final snapshot = await document.get();
      return LeadModel.fromFirestore(snapshot);
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to update lead. Please try again.');
    }
  }

  @override
  Future<LeadModel> getLeadById({
    required String companyId,
    required String leadId,
  }) async {
    try {
      final snapshot = await _leadsCollection(companyId).doc(leadId).get();
      if (!snapshot.exists) {
        throw const LeadException('Unable to load lead.');
      }
      final lead = LeadModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, lead: lead);
      return lead;
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to load lead.');
    }
  }

  @override
  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
  }) async {
    try {
      final document = _leadsCollection(companyId).doc(leadId);
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const LeadException('Unable to load lead.');
      }
      final lead = LeadModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, lead: lead);
      await document.update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': archivedBy,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': archivedBy,
      });
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to archive lead. Please try again.');
    }
  }

  @override
  Stream<List<LeadModel>> watchLeads({
    required String companyId,
    String? assignedTo,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _leadsCollection(companyId);
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final leads = snapshot.docs
          .map((document) {
            final lead = LeadModel.fromFirestore(document);
            _ensureSameCompany(companyId: companyId, lead: lead);
            return lead;
          })
          .where((lead) {
            return !lead.isArchived;
          })
          .toList();

      leads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return leads;
    });
  }

  CollectionReference<Map<String, dynamic>> _leadsCollection(String companyId) {
    return _firestore.collection(FirebasePaths.companyLeads(companyId));
  }
}

String _normalizeEmail(String value) {
  return value.trim().toLowerCase();
}

String _normalizePhone(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').trim();
}

void _ensureSameCompany({required String companyId, required LeadModel lead}) {
  if (companyId.isEmpty || lead.companyId != companyId) {
    throw const LeadException(
      'You do not have permission to access this lead.',
    );
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
      return 'Unable to load leads. Please try again.';
  }
}
