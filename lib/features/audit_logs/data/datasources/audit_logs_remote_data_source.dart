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
    final logToSave = AuditLogModel(
      id: document.id,
      companyId: companyId,
      actorId: auditLog.actorId,
      actorName: _firstNonEmpty(actor.name, auditLog.actorName),
      actorEmail: _firstNonEmpty(actor.email, auditLog.actorEmail),
      actorRole: _firstNonEmpty(actor.role, auditLog.actorRole),
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
      managerId: _firstNonEmpty(
        _metadataString(auditLog.metadata, 'managerId', auditLog.managerId),
        assignedUser.managerId,
      ),
      managerName: _firstNonEmpty(
        _metadataString(auditLog.metadata, 'managerName', auditLog.managerName),
        assignedUser.managerName,
      ),
      createdAt: auditLog.createdAt,
      metadata: auditLog.metadata,
    );

    try {
      await document.set(logToSave.toFirestore());
    } catch (error, stackTrace) {
      debugPrint(
        'Masar audit log write failed for $companyId/${document.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
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
        .map(
          (snapshot) => _filterAuditLogs(
            _mapAuditLogSnapshot(snapshot, companyId, queryLimit),
            module: module,
            action: action,
            actorId: actorId,
            startAt: startAt,
            endAt: endAt,
            limit: limit,
            hideManagerRestrictedLogs: false,
          ),
        );
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
    final collection = _auditLogsCollection(companyId);
    // Keep manager reads scoped in Firestore, but avoid composite-index-heavy
    // order/filter combinations. The result is over-fetched, merged, filtered,
    // and sorted locally inside this safe manager/team scope.
    final queryLimit = _auditOverfetchQueryLimit(limit);
    final queries = <Query<Map<String, dynamic>>>[
      collection.where('managerId', isEqualTo: managerId).limit(queryLimit),
    ];

    if (teamId.isNotEmpty) {
      queries.add(collection.where('teamId', isEqualTo: teamId).limit(queryLimit));
    }

    final controller = StreamController<List<AuditLogModel>>();
    final latest = <int, List<AuditLogModel>>{};
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
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
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(List<AuditLogModel>.unmodifiable(merged.take(limit)));
    }

    for (var i = 0; i < queries.length; i++) {
      final index = i;
      final subscription = queries[index].snapshots().listen(
        (snapshot) {
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
          if (!isClosed && !controller.isClosed) {
            controller.addError(error, stackTrace);
          }
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
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    final logs = snapshot.docs.map((document) {
      final auditLog = AuditLogModel.fromFirestore(document);
      if (auditLog.companyId != companyId) {
        throw StateError('Audit log company mismatch.');
      }
      return auditLog;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List<AuditLogModel>.unmodifiable(logs.take(limit));
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

class _AuditActorSnapshot {
  const _AuditActorSnapshot({
    required this.name,
    required this.email,
    required this.role,
  });

  const _AuditActorSnapshot.empty() : this(name: '', email: '', role: '');

  final String name;
  final String email;
  final String role;
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
