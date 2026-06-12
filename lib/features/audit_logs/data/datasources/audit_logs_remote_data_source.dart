import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../domain/entities/audit_log.dart';
import '../models/audit_log_model.dart';

abstract interface class AuditLogsRemoteDataSource {
  Future<void> createAuditLog({
    required String companyId,
    required AuditLogModel auditLog,
  });

  Stream<List<AuditLogModel>> watchAuditLogs({
    required String companyId,
    String? managerId,
    String? teamId,
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    bool hasSearchFilter = false,
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  });
}

class FirestoreAuditLogsRemoteDataSource
    implements AuditLogsRemoteDataSource {
  FirestoreAuditLogsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _defaultFetchBuffer = 20;
  static const int _overfetchMultiplier = 5;
  static const int _maxFetchLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createAuditLog({
    required String companyId,
    required AuditLogModel auditLog,
  }) async {
    if (companyId.isEmpty || auditLog.companyId != companyId) {
      return;
    }

    final collection = _auditLogsCollection(companyId);
    final document = auditLog.id.isEmpty
        ? collection.doc()
        : collection.doc(auditLog.id);
    final actor = await _loadActorSnapshot(
      companyId: companyId,
      actorId: auditLog.actorId,
    );
    final assignedUser = await _loadAssignedUserSnapshot(
      companyId: companyId,
      assignedTo: _metadataString(
        auditLog.metadata,
        'assignedTo',
        auditLog.assignedTo,
      ),
    );
    final actorName = actor.found
        ? actor.name
        : _firstNonEmpty(actor.name, auditLog.actorName);
    final actorEmail = actor.found
        ? actor.email
        : _firstNonEmpty(actor.email, auditLog.actorEmail);
    final actorRole = actor.found
        ? actor.role
        : _firstNonEmpty(actor.role, auditLog.actorRole);
    final scopedManagerId = _firstNonEmpty(
      _firstNonEmpty(
        _metadataString(auditLog.metadata, 'managerId', auditLog.managerId),
        assignedUser.managerId,
      ),
      actorRole == 'manager' ? auditLog.actorId : '',
    );
    final scopedManagerName = _firstNonEmpty(
      _firstNonEmpty(
        _metadataString(auditLog.metadata, 'managerName', auditLog.managerName),
        assignedUser.managerName,
      ),
      actorRole == 'manager' ? actorName : '',
    );
    final logToSave = AuditLogModel(
      id: document.id,
      companyId: companyId,
      actorId: auditLog.actorId,
      actorName: actorName,
      actorEmail: actorEmail,
      actorRole: actorRole,
      action: auditLog.action,
      module: auditLog.module,
      recordId: auditLog.recordId,
      recordTitle: auditLog.recordTitle,
      recordSubtitle: auditLog.recordSubtitle,
      assignedTo: _metadataString(auditLog.metadata, 'assignedTo', auditLog.assignedTo),
      teamId: _firstNonEmpty(
        _metadataString(auditLog.metadata, 'teamId', auditLog.teamId),
        assignedUser.teamId,
      ),
      teamName: _firstNonEmpty(
        _metadataString(auditLog.metadata, 'teamName', auditLog.teamName),
        assignedUser.teamName,
      ),
      managerId: scopedManagerId,
      managerName: scopedManagerName,
      createdAt: auditLog.createdAt,
      metadata: auditLog.metadata,
    );

    try {
      // Keep the audit timestamp tied to the actual user action, not to a later
      // cache flush / delayed best-effort write. Firestore rules only allow the
      // audit schema fields, so do not add auxiliary client/server timestamp
      // fields here.
      final payload = logToSave.toFirestore();
      payload['createdAt'] = Timestamp.fromDate(
        _safeAuditEventTime(auditLog.createdAt),
      );
      await document.set(payload);
    } catch (error, stackTrace) {
      debugPrint(
        'Masar audit log write failed for $companyId/${document.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<AuditLogModel>> watchAuditLogs({
    required String companyId,
    String? managerId,
    String? teamId,
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    bool hasSearchFilter = false,
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  }) {
    final cleanManagerId = managerId?.trim() ?? '';
    final cleanTeamId = teamId?.trim() ?? '';
    if (cleanManagerId.isNotEmpty) {
      return _watchManagerScopedAuditLogs(
        companyId: companyId,
        managerId: cleanManagerId,
        teamId: cleanTeamId,
        module: module,
        action: action,
        actorId: actorId,
        startAt: startAt,
        endAt: endAt,
        limit: limit,
      );
    }

    final queryLimit = _auditQueryLimit(
      limit,
      hasLocalFilters: _hasLocalAuditFilters(
        module: module,
        action: action,
        actorId: actorId,
        hasSearchFilter: hasSearchFilter,
      ),
    );
    return _applyAuditDateWindow(
          _auditLogsCollection(companyId),
          startAt: startAt,
          endAt: endAt,
        )
        .limit(queryLimit)
        .snapshots()
        .map((snapshot) {
          _debugAudit(
            'admin/company snapshot company=$companyId docs=${snapshot.docs.length} '
            'limit=$queryLimit fromCache=${snapshot.metadata.isFromCache} '
            'pending=${snapshot.metadata.hasPendingWrites} ids=${_debugSnapshotIds(snapshot)}',
          );
          return _filterAuditLogs(
            _mapAuditLogSnapshot(snapshot, companyId, queryLimit),
            module: module,
            action: action,
            actorId: actorId,
            startAt: startAt,
            endAt: endAt,
            limit: limit,
            hideManagerRestrictedLogs: false,
          );
        }).handleError((Object error, StackTrace stackTrace) {
          _debugAuditStreamError(
            label: 'audit.adminCompany',
            companyId: companyId,
            error: error,
            stackTrace: stackTrace,
            context:
                'module=${module?.name ?? ''} action=${action?.name ?? ''} '
                'actorId=${actorId ?? ''} startAt=${startAt?.toIso8601String() ?? ''} '
                'endAt=${endAt?.toIso8601String() ?? ''} limit=$queryLimit',
          );
          throw error;
        });
  }

  Stream<List<AuditLogModel>> _watchManagerScopedAuditLogs({
    required String companyId,
    required String managerId,
    required String teamId,
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    DateTime? startAt,
    DateTime? endAt,
    required int limit,
  }) {
    // Keep Manager audit/recent activity on the central company audit log
    // collection, but do not collapse the scope to only managerId. Some valid
    // team audit rows are scoped by teamId, while other rows are scoped directly
    // by managerId. Query both scoped branches with createdAt ordering, merge
    // them locally, and never fall back to an unordered limited query because
    // that is what made Recent Activity look stuck on old rows.
    final collection = _auditLogsCollection(companyId);
    final queryLimit = _auditOverfetchQueryLimit(limit);
    final queries = <_AuditScopedQuery>[
      _AuditScopedQuery(
        label: 'managerId',
        query: _applyAuditDateWindow(
          collection.where('managerId', isEqualTo: managerId),
          startAt: startAt,
          endAt: endAt,
        ).limit(queryLimit),
      ),
    ];
    if (teamId.isNotEmpty) {
      queries.add(
        _AuditScopedQuery(
          label: 'teamId',
          query: _applyAuditDateWindow(
            collection.where('teamId', isEqualTo: teamId),
            startAt: startAt,
            endAt: endAt,
          ).limit(queryLimit),
        ),
      );
    }

    _debugAudit(
      'manager scoped watch start company=$companyId managerId=$managerId '
      'teamId=$teamId queryCount=${queries.length} limit=$limit '
      'queryLimit=$queryLimit module=${module?.name ?? ''} '
      'action=${action?.name ?? ''} actorId=${actorId ?? ''} '
      'startAt=${startAt?.toIso8601String() ?? ''} '
      'endAt=${endAt?.toIso8601String() ?? ''}',
    );

    final controller = StreamController<List<AuditLogModel>>();
    final latest = <int, List<AuditLogModel>>{};
    final queryErrors = <int, Object>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    var isClosed = false;

    void emitMerged() {
      if (isClosed || controller.isClosed) {
        return;
      }
      final byId = <String, AuditLogModel>{};
      for (final logs in latest.values) {
        for (final log in logs) {
          byId[log.id] = log;
        }
      }
      final merged = byId.values.toList()..sort(_compareAuditLogs);
      _debugAudit(
        'manager scoped merged company=$companyId managerId=$managerId '
        'teamId=$teamId docs=${merged.length} errors=${queryErrors.length} '
        'ids=${merged.take(8).map((log) => log.id).join(',')}',
      );
      if (merged.isEmpty && latest.isEmpty && queryErrors.length == queries.length) {
        controller.addError(
          queryErrors.values.first,
          StackTrace.current,
        );
        return;
      }
      controller.add(List<AuditLogModel>.unmodifiable(merged.take(limit)));
    }

    for (var index = 0; index < queries.length; index++) {
      final scopedQuery = queries[index];
      late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
          subscription;
      subscription = scopedQuery.query.snapshots().listen(
        (snapshot) {
          queryErrors.remove(index);
          _debugAudit(
            'manager ${scopedQuery.label} snapshot company=$companyId '
            'managerId=$managerId teamId=$teamId docs=${snapshot.docs.length} '
            'limit=$queryLimit fromCache=${snapshot.metadata.isFromCache} '
            'pending=${snapshot.metadata.hasPendingWrites} '
            'ids=${_debugSnapshotIds(snapshot)}',
          );
          final mapped = _mapAuditLogSnapshot(snapshot, companyId, queryLimit);
          latest[index] = _filterAuditLogs(
            mapped,
            module: module,
            action: action,
            actorId: actorId,
            startAt: startAt,
            endAt: endAt,
            limit: limit * 2,
            hideManagerRestrictedLogs: true,
          );
          emitMerged();
        },
        onError: (Object error, StackTrace stackTrace) {
          queryErrors[index] = error;
          latest.remove(index);
          _debugAuditStreamError(
            label: 'audit.manager.${scopedQuery.label}',
            companyId: companyId,
            error: error,
            stackTrace: stackTrace,
            context:
                'managerId=$managerId teamId=$teamId limit=$queryLimit '
                'module=${module?.name ?? ''} action=${action?.name ?? ''} '
                'actorId=${actorId ?? ''} startAt=${startAt?.toIso8601String() ?? ''} '
                'endAt=${endAt?.toIso8601String() ?? ''}',
          );
          emitMerged();
        },
      );
      subscriptions.add(subscription);
    }

    controller.onCancel = () async {
      isClosed = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Query<Map<String, dynamic>> _applyAuditDateWindow(
    Query<Map<String, dynamic>> query, {
    DateTime? startAt,
    DateTime? endAt,
  }) {
    if (startAt != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startAt),
      );
    }
    if (endAt != null) {
      query = query.where('createdAt', isLessThan: Timestamp.fromDate(endAt));
    }
    return query.orderBy('createdAt', descending: true);
  }


  bool _hasLocalAuditFilters({
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    required bool hasSearchFilter,
  }) {
    return module != null ||
        action != null ||
        (actorId?.trim().isNotEmpty ?? false) ||
        hasSearchFilter;
  }

  int _auditQueryLimit(int limit, {required bool hasLocalFilters}) {
    if (hasLocalFilters) {
      return _auditOverfetchQueryLimit(limit);
    }
    final normalizedLimit = limit <= 0 ? 20 : limit;
    final requested = normalizedLimit + _defaultFetchBuffer;
    if (requested < normalizedLimit) {
      return normalizedLimit;
    }
    return requested > _maxFetchLimit ? _maxFetchLimit : requested;
  }

  int _auditOverfetchQueryLimit(int limit) {
    final normalizedLimit = limit <= 0 ? 20 : limit;
    final requested = normalizedLimit * _overfetchMultiplier;
    if (requested < normalizedLimit) {
      return normalizedLimit;
    }
    return requested > _maxFetchLimit ? _maxFetchLimit : requested;
  }

  List<AuditLogModel> _filterAuditLogs(
    List<AuditLogModel> logs, {
    AuditLogModule? module,
    AuditLogAction? action,
    String? actorId,
    DateTime? startAt,
    DateTime? endAt,
    required int limit,
    required bool hideManagerRestrictedLogs,
  }) {
    final cleanActorId = actorId?.trim() ?? '';
    final filtered = logs.where((log) {
      if (hideManagerRestrictedLogs && _managerShouldHideAuditLog(log)) {
        return false;
      }
      if (module != null && !_matchesAuditModuleFilter(log, module)) {
        return false;
      }
      if (action != null && log.action != action) {
        return false;
      }
      if (cleanActorId.isNotEmpty && log.actorId != cleanActorId) {
        return false;
      }
      if (startAt != null && log.createdAt.isBefore(startAt)) {
        return false;
      }
      if (endAt != null && !log.createdAt.isBefore(endAt)) {
        return false;
      }
      return true;
    }).toList()
      ..sort(_compareAuditLogs);
    return List<AuditLogModel>.unmodifiable(filtered.take(limit));
  }

  bool _matchesAuditModuleFilter(AuditLogModel log, AuditLogModule module) {
    if (module == AuditLogModule.exports) {
      return log.module == AuditLogModule.exports || _isExportAuditLog(log);
    }
    return log.module == module;
  }

  bool _isExportAuditLog(AuditLogModel log) {
    return log.action == AuditLogAction.exported ||
        log.action == AuditLogAction.exportGenerated ||
        log.metadata.containsKey('exportType') ||
        log.metadata.containsKey('exportScope');
  }

  bool _managerShouldHideAuditLog(AuditLogModel log) {
    if (log.module == AuditLogModule.exports ||
        log.module == AuditLogModule.reports ||
        log.module == AuditLogModule.auditLogs ||
        _isExportAuditLog(log)) {
      return true;
    }
    return log.metadata.containsKey('exportType') ||
        log.metadata.containsKey('exportScope') ||
        log.metadata.containsKey('auditLogId') &&
            (log.metadata['exportType']?.toString().isNotEmpty ?? false);
  }

  List<AuditLogModel> _mapAuditLogSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String companyId,
    int limit,
  ) {
    final logs = <AuditLogModel>[];
    for (final document in snapshot.docs) {
      if (document.metadata.hasPendingWrites) {
        // Do not render local latency-compensated audit rows. If Firestore rules
        // reject the write, those rows vanish on the next server snapshot and
        // the UI looks like recent activity is flickering or reverting.
        continue;
      }
      try {
        final auditLog = AuditLogModel.fromFirestore(document);
        if (auditLog.companyId != companyId) {
          continue;
        }
        logs.add(auditLog);
      } catch (error, stackTrace) {
        debugPrint('Masar audit log read skipped for ${document.id}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    logs.sort(_compareAuditLogs);

    return List<AuditLogModel>.unmodifiable(logs.take(limit));
  }

  int _compareAuditLogs(AuditLogModel a, AuditLogModel b) {
    final timeCompare = b.createdAt.compareTo(a.createdAt);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return b.id.compareTo(a.id);
  }

  CollectionReference<Map<String, dynamic>> _auditLogsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyAuditLogs(companyId));
  }


  Future<_AssignedUserSnapshot> _loadAssignedUserSnapshot({
    required String companyId,
    required String assignedTo,
  }) async {
    final uid = assignedTo.trim();
    if (uid.isEmpty) {
      return const _AssignedUserSnapshot.empty();
    }

    try {
      final snapshot = await _firestore
          .doc(FirebasePaths.companyUser(companyId: companyId, uid: uid))
          .get();
      final data = snapshot.data();
      if (data == null) {
        return const _AssignedUserSnapshot.empty();
      }

      return _AssignedUserSnapshot(
        teamId: data['teamId'] as String? ?? '',
        teamName: data['teamName'] as String? ?? '',
        managerId: data['managerId'] as String? ?? '',
        managerName: data['managerName'] as String? ?? '',
      );
    } catch (_) {
      return const _AssignedUserSnapshot.empty();
    }
  }

  Future<_AuditActorSnapshot> _loadActorSnapshot({
    required String companyId,
    required String actorId,
  }) async {
    if (actorId.trim().isEmpty) {
      return const _AuditActorSnapshot.empty();
    }

    try {
      final snapshot = await _firestore
          .doc(FirebasePaths.companyUser(companyId: companyId, uid: actorId))
          .get();
      final data = snapshot.data();
      if (data == null) {
        return const _AuditActorSnapshot.empty();
      }

      return _AuditActorSnapshot(
        name: data['fullName'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: data['role'] as String? ?? '',
      );
    } catch (_) {
      return const _AuditActorSnapshot.empty();
    }
  }
}


class _AssignedUserSnapshot {
  const _AssignedUserSnapshot({
    required this.teamId,
    required this.teamName,
    required this.managerId,
    required this.managerName,
  });

  const _AssignedUserSnapshot.empty()
      : this(teamId: '', teamName: '', managerId: '', managerName: '');

  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
}


class _AuditScopedQuery {
  const _AuditScopedQuery({required this.label, required this.query});

  final String label;
  final Query<Map<String, dynamic>> query;
}


void _debugAuditStreamError({
  required String label,
  required String companyId,
  required Object error,
  StackTrace? stackTrace,
  String context = '',
}) {
  if (error is FirebaseException) {
    final indexLink = _firebaseIndexLink(error);
    _debugAudit(
      '$label firebase company=$companyId code=${error.code} '
      'indexLink=${indexLink ?? ''} context=$context '
      'message=${error.message}',
      stackTrace,
    );
    if (indexLink != null && indexLink.isNotEmpty) {
      _masarFirebaseIndexDebug('$label missingIndexLink=$indexLink');
    }
    return;
  }
  _debugAudit(
    '$label error company=$companyId type=${error.runtimeType} '
    'context=$context error=$error',
    stackTrace,
  );
}

void _masarFirebaseIndexDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarFirebaseIndexDebug $message');
}

String? _firebaseIndexLink(FirebaseException error) {
  final message = error.message;
  if (message == null || message.isEmpty) {
    return null;
  }
  final match = RegExp(r'https://console\.firebase\.google\.com/\S+')
      .firstMatch(message);
  final rawLink = match?.group(0);
  if (rawLink == null || rawLink.isEmpty) {
    return null;
  }
  var link = rawLink;
  while (link.endsWith('.') || link.endsWith(',') || link.endsWith(')')) {
    link = link.substring(0, link.length - 1);
  }
  return link;
}

void _debugAudit(String message, [StackTrace? stackTrace]) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarAuditDebug $message');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}

String _debugSnapshotIds(QuerySnapshot<Map<String, dynamic>> snapshot) {
  if (!kDebugMode) {
    return '';
  }
  return snapshot.docs.take(8).map((doc) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final managerId = data['managerId'];
    final teamId = data['teamId'];
    final module = data['module'];
    final action = data['action'];
    return '${doc.id}($module/$action m=$managerId t=$teamId at=$createdAt)';
  }).join(',');
}

class _AuditActorSnapshot {
  const _AuditActorSnapshot({
    required this.name,
    required this.email,
    required this.role,
    this.found = true,
  });

  const _AuditActorSnapshot.empty()
      : this(name: '', email: '', role: '', found: false);

  final String name;
  final String email;
  final String role;
  final bool found;
}

String _firstNonEmpty(String primary, String fallback) {
  final value = primary.trim();
  if (value.isNotEmpty) {
    return value;
  }
  return fallback.trim();
}

String _metadataString(
  Map<String, Object?> metadata,
  String key,
  String fallback,
) {
  final value = metadata[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback.trim();
}


DateTime _safeAuditEventTime(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();
  if (local.isAfter(now.add(const Duration(minutes: 5)))) {
    return now;
  }
  if (local.isBefore(now.subtract(const Duration(days: 366)))) {
    return now;
  }
  return local;
}
