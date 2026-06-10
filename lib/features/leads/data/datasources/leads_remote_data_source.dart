import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/lead.dart';
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
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? followUpFilter,
    String? workQueueFilter,
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
      final result = await _functions.httpsCallable('checkDuplicateLead').call(
        <String, Object?>{
          'companyId': companyId,
          'phone': phone,
          'email': email,
          if ((excludeLeadId ?? '').trim().isNotEmpty)
            'excludeLeadId': excludeLeadId!.trim(),
        },
      );
      final data = result.data;
      if (data is Map) {
        return data['duplicate'] == true;
      }
      return false;
    } on LeadException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'permission-denied') {
        return false;
      }
      throw LeadException(_mapFunctionsError(error));
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
    final collection = _leadsCollection(companyId);
    final document = lead.id.isEmpty
        ? collection.doc()
        : collection.doc(lead.id);
    final leadToSave = LeadModel.fromEntity(
      lead.copyWith(id: document.id, companyId: companyId, isArchived: false),
    );
    try {
      await _saveLeadRecord(
        companyId: companyId,
        operation: 'create',
        lead: leadToSave,
      );
      return _loadLeadAfterConfirmedWrite(
        companyId: companyId,
        document: document,
        fallback: leadToSave,
      );
    } on LeadException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      if (_isUncertainLeadWriteError(error.code)) {
        final savedLead = await _tryLoadSavedLead(
          companyId: companyId,
          document: document,
        );
        if (savedLead != null) {
          return savedLead;
        }
      }
      throw LeadException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      if (_isUncertainLeadWriteError(error.code)) {
        final savedLead = await _tryLoadSavedLead(
          companyId: companyId,
          document: document,
        );
        if (savedLead != null) {
          return savedLead;
        }
      }
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
      return _loadLeadAfterConfirmedWrite(
        companyId: companyId,
        document: document,
        fallback: lead,
      );
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

  Future<LeadModel?> _tryLoadSavedLead({
    required String companyId,
    required DocumentReference<Map<String, dynamic>> document,
  }) async {
    try {
      final snapshot = await document.get(
        const GetOptions(source: Source.server),
      );
      if (!snapshot.exists) {
        return null;
      }
      final savedLead = LeadModel.fromFirestore(snapshot);
      if (savedLead.companyId != companyId) {
        return null;
      }
      return savedLead;
    } catch (_) {
      return null;
    }
  }

  Future<LeadModel> _loadLeadAfterConfirmedWrite({
    required String companyId,
    required DocumentReference<Map<String, dynamic>> document,
    required LeadModel fallback,
  }) async {
    try {
      final snapshot = await document.get(
        const GetOptions(source: Source.server),
      );
      if (snapshot.exists) {
        final savedLead = LeadModel.fromFirestore(snapshot);
        if (savedLead.companyId == companyId) {
          return savedLead;
        }
      }
    } catch (_) {
      // The callable already confirmed the write. Returning the intended model
      // avoids showing stale cached data while the role-scoped stream catches up
      // on slow connections.
    }
    return fallback;
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
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? followUpFilter,
    String? workQueueFilter,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _leadsCollection(companyId);
    if (archiveFilter == ArchiveFilter.archived) {
      query = query.where('isArchived', isEqualTo: true);
    } else if (archiveFilter == ArchiveFilter.active) {
      query = query.where('isArchived', isEqualTo: false);
    }
    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    final queryConfig = _applyLeadListFilters(
      query,
      statusFilter: statusFilter,
      sourceFilter: sourceFilter,
      priorityFilter: priorityFilter,
      followUpFilter: followUpFilter,
      workQueueFilter: workQueueFilter,
    );
    query = queryConfig.query;

    return query
        .orderBy(queryConfig.orderByField, descending: queryConfig.descending)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
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
        _logWatchLeadsFailure(
          error: error,
          archiveFilter: archiveFilter,
          assignedTo: assignedTo,
          managerId: managerId,
          teamId: teamId,
        );
        throw LeadException(_mapFirestoreError(error));
      }
      throw const LeadException(AppErrorMessages.unknown);
    });
  }


  CollectionReference<Map<String, dynamic>> _leadsCollection(String companyId) {
    return _firestore.collection(FirebasePaths.companyLeads(companyId));
  }
}

class _LeadListQueryConfig {
  const _LeadListQueryConfig({
    required this.query,
    required this.orderByField,
    required this.descending,
  });

  final Query<Map<String, dynamic>> query;
  final String orderByField;
  final bool descending;
}

_LeadListQueryConfig _applyLeadListFilters(
  Query<Map<String, dynamic>> query, {
  required LeadStatus? statusFilter,
  required LeadSource? sourceFilter,
  required LeadPriority? priorityFilter,
  required String? followUpFilter,
  required String? workQueueFilter,
}) {
  // Secondary filters are intentionally not applied here for this repair pass.
  // The Leads Cubit keeps role/company/archive/assignee scope server-side and
  // applies status/source/priority/follow-up/work-queue filters locally to the
  // currently loaded scoped page. That stops missing-index filter changes from
  // breaking the entire Leads page. Re-introduce server-side filtered lists only
  // after each exact query shape has a confirmed deployed Firestore index.
  return _createdAtLeadListQuery(query);
}

const List<String> _activeLeadStatusValues = <String>[
  'new',
  'contacted',
  'interested',
  'visitScheduled',
  'negotiation',
];

_LeadListQueryConfig _createdAtLeadListQuery(Query<Map<String, dynamic>> query) {
  return _LeadListQueryConfig(
    query: query,
    orderByField: 'createdAt',
    descending: true,
  );
}

_LeadListQueryConfig _followUpLeadListQuery(Query<Map<String, dynamic>> query) {
  return _LeadListQueryConfig(
    query: query,
    orderByField: 'nextFollowUpAt',
    descending: false,
  );
}

DateTime _startOfLocalDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

void _logWatchLeadsFailure({
  required FirebaseException error,
  required ArchiveFilter archiveFilter,
  required String? assignedTo,
  required String? managerId,
  required String? teamId,
}) {
  if (!kDebugMode) {
    return;
  }
  final message = _sanitizeDiagnosticText(error.message ?? '');
  debugPrint(
    'MasarLeadsQuery: code=${error.code} '
    'scope=${_watchLeadsScopeLabel(assignedTo: assignedTo, managerId: managerId, teamId: teamId)} '
    'archive=${archiveFilter.name} message=$message',
  );
}

String _watchLeadsScopeLabel({
  required String? assignedTo,
  required String? managerId,
  required String? teamId,
}) {
  if (teamId != null && teamId.trim().isNotEmpty) {
    return 'team';
  }
  if (managerId != null && managerId.trim().isNotEmpty) {
    return 'manager';
  }
  if (assignedTo != null && assignedTo.trim().isNotEmpty) {
    return 'assigned';
  }
  return 'company';
}

String _sanitizeDiagnosticText(String value) {
  return value
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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
  return value.replaceAll(RegExp(r'[()\-\s]+'), '').trim();
}

void _ensureSameCompany({required String companyId, required LeadModel lead}) {
  if (companyId.isEmpty || lead.companyId != companyId) {
    throw const LeadException(
      'You do not have permission to access this lead.',
    );
  }
}


bool _isUncertainLeadWriteError(String code) {
  return code == 'unavailable' ||
      code == 'deadline-exceeded' ||
      code == 'cancelled' ||
      code == 'network-request-failed';
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
