import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/archive/archive_filter.dart';
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
    String reason = '',
  });

  Future<void> restoreLead({
    required String companyId,
    required String leadId,
    required String restoredBy,
  });

  Stream<List<LeadModel>> watchLeads({
    required String companyId,
    String? assignedTo,
    String? managerId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  });
}

class FirestoreLeadsRemoteDataSource implements LeadsRemoteDataSource {
  FirestoreLeadsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

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
      if (error.code == 'permission-denied') {
        return false;
      }
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
      await _saveLeadRecord(
        companyId: companyId,
        operation: 'create',
        lead: leadToSave,
      );
      final snapshot = await document.get();
      return LeadModel.fromFirestore(snapshot);
    } on LeadException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw LeadException(_mapFunctionsError(error));
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
      await _saveLeadRecord(
        companyId: companyId,
        operation: 'update',
        lead: lead,
      );
      final document = _leadsCollection(companyId).doc(lead.id);
      final snapshot = await document.get();
      return LeadModel.fromFirestore(snapshot);
    } on LeadException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw LeadException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to update lead. Please try again.');
    }
  }

  Future<void> _saveLeadRecord({
    required String companyId,
    required String operation,
    required LeadModel lead,
  }) async {
    await _functions.httpsCallable('saveLeadRecord').call(<String, Object?>{
      'companyId': companyId,
      'operation': operation,
      'lead': _leadCallableData(lead),
    });
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
    String reason = '',
  }) async {
    try {
      await _functions.httpsCallable('archiveCrmRecord').call(<String, Object?>{
        'companyId': companyId,
        'module': 'leads',
        'recordId': leadId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (error) {
      throw LeadException(_mapFunctionsError(error));
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to archive lead. Please try again.');
    }
  }

  @override
  Future<void> restoreLead({
    required String companyId,
    required String leadId,
    required String restoredBy,
  }) async {
    try {
      await _functions.httpsCallable('restoreCrmRecord').call(<String, Object?>{
        'companyId': companyId,
        'module': 'leads',
        'recordId': leadId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw LeadException(_mapFunctionsError(error));
    } on LeadException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to restore lead. Please try again.');
    }
  }

  @override
  Stream<List<LeadModel>> watchLeads({
    required String companyId,
    String? assignedTo,
    String? managerId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _leadsCollection(companyId);
    if (archiveFilter == ArchiveFilter.archived) {
      query = query.where('isArchived', isEqualTo: true);
    } else if (archiveFilter == ArchiveFilter.active) {
      query = query.where('isArchived', isEqualTo: false);
    }
    if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final leads = snapshot.docs
          .map((document) {
            final lead = LeadModel.fromFirestore(document);
            _ensureSameCompany(companyId: companyId, lead: lead);
            return lead;
          })
          .where((lead) {
            if (archiveFilter == ArchiveFilter.archived) {
              return lead.isArchived;
            }
            if (archiveFilter == ArchiveFilter.active) {
              return !lead.isArchived;
            }
            return true;
          })
          .toList();

      leads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return leads;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw LeadException(_mapFirestoreError(error));
      }
      throw const LeadException(AppErrorMessages.unknown);
    });
  }

  CollectionReference<Map<String, dynamic>> _leadsCollection(String companyId) {
    return _firestore.collection(FirebasePaths.companyLeads(companyId));
  }
}


Map<String, Object?> _leadCallableData(LeadModel lead) {
  return {
    'id': lead.id,
    'companyId': lead.companyId,
    'fullName': lead.fullName,
    'phone': lead.phone,
    'email': lead.email,
    'source': leadSourceToValue(lead.source),
    'sourceDetails': lead.sourceDetails,
    'status': leadStatusToValue(lead.status),
    'priority': leadPriorityToValue(lead.priority),
    'budgetMin': lead.budgetMin,
    'budgetMax': lead.budgetMax,
    'preferredLocation': lead.preferredLocation,
    'preferredPropertyType': lead.preferredPropertyType,
    'assignedTo': lead.assignedTo,
    'assignedToName': lead.assignedToName,
    'teamId': lead.teamId,
    'teamName': lead.teamName,
    'managerId': lead.managerId,
    'managerName': lead.managerName,
    'notes': lead.notes,
    'lastContactAt': _dateToCallable(lead.lastContactAt),
    'nextFollowUpAt': _dateToCallable(lead.nextFollowUpAt),
    'isArchived': lead.isArchived,
    'archivedAt': _dateToCallable(lead.archivedAt),
    'archivedBy': lead.archivedBy,
    'archivedByName': lead.archivedByName,
    'archiveReason': lead.archiveReason,
    'restoredAt': _dateToCallable(lead.restoredAt),
    'restoredBy': lead.restoredBy,
    'restoredByName': lead.restoredByName,
  };
}

String? _dateToCallable(DateTime? value) {
  if (value == null) {
    return null;
  }
  return value.toUtc().toIso8601String();
}

Map<String, dynamic> _leadUpdateData(LeadModel lead) {
  return {
    'fullName': lead.fullName,
    'phone': lead.phone,
    'email': lead.email,
    'source': leadSourceToValue(lead.source),
    'sourceDetails': lead.sourceDetails,
    'status': leadStatusToValue(lead.status),
    'priority': leadPriorityToValue(lead.priority),
    'budgetMin': lead.budgetMin,
    'budgetMax': lead.budgetMax,
    'preferredLocation': lead.preferredLocation,
    'preferredPropertyType': lead.preferredPropertyType,
    'assignedTo': lead.assignedTo,
    'assignedToName': lead.assignedToName,
    'teamId': lead.teamId,
    'teamName': lead.teamName,
    'managerId': lead.managerId,
    'managerName': lead.managerName,
    'notes': lead.notes,
    'updatedAt': Timestamp.fromDate(lead.updatedAt),
    'updatedBy': lead.updatedBy,
    'lastContactAt': _timestampFromNullableDate(lead.lastContactAt),
    'nextFollowUpAt': _timestampFromNullableDate(lead.nextFollowUpAt),
    'isArchived': lead.isArchived,
    'archivedAt': lead.archivedAt == null
        ? null
        : Timestamp.fromDate(lead.archivedAt!),
    'archivedBy': lead.archivedBy,
  };
}

Timestamp? _timestampFromNullableDate(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
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


String _mapFunctionsError(FirebaseFunctionsException error) {
  switch (error.code) {
    case 'unavailable':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    case 'already-exists':
      return 'Lead already exists.';
    case 'invalid-argument':
    case 'failed-precondition':
      return error.message ?? AppErrorMessages.permissionDenied;
    default:
      return AppErrorMessages.permissionDenied;
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
