import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../domain/errors/lead_exception.dart';
import '../models/lead_model.dart';

abstract interface class LeadsRemoteDataSource {
  Future<LeadModel> createLead({
    required String companyId,
    required LeadModel lead,
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
    return _leadsCollection(companyId).limit(limit).snapshots().map((snapshot) {
      final leads = snapshot.docs
          .map((document) {
            final lead = LeadModel.fromFirestore(document);
            _ensureSameCompany(companyId: companyId, lead: lead);
            return lead;
          })
          .where((lead) {
            final matchesAssignment =
                assignedTo == null ||
                assignedTo.isEmpty ||
                lead.assignedTo == assignedTo;
            return !lead.isArchived && matchesAssignment;
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

void _ensureSameCompany({required String companyId, required LeadModel lead}) {
  if (companyId.isEmpty || lead.companyId != companyId) {
    throw const LeadException(
      'You do not have permission to access this lead.',
    );
  }
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return 'You do not have permission to access leads.';
    case 'unavailable':
      return 'Connection error. Check your internet connection.';
    default:
      return 'Unable to load leads. Please try again.';
  }
}
