import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
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
    int limit,
  });
}

class FirestoreAuditLogsRemoteDataSource
    implements AuditLogsRemoteDataSource {
  FirestoreAuditLogsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
      actorName: _firstNonEmpty(auditLog.actorName, actor.name),
      actorEmail: _firstNonEmpty(auditLog.actorEmail, actor.email),
      actorRole: _firstNonEmpty(auditLog.actorRole, actor.role),
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

    await document.set(logToSave.toFirestore());
  }

  @override
  Stream<List<AuditLogModel>> watchAuditLogs({
    required String companyId,
    String? managerId,
    String? teamId,
    int limit = 20,
  }) {
    final cleanManagerId = managerId?.trim() ?? '';
    final cleanTeamId = teamId?.trim() ?? '';

    if (cleanManagerId.isNotEmpty) {
      return _watchManagerScopedAuditLogs(
        companyId: companyId,
        managerId: cleanManagerId,
        teamId: cleanTeamId,
        limit: limit,
      );
    }

    return _auditLogsCollection(companyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => _mapAuditLogSnapshot(snapshot, companyId, limit));
  }

  Stream<List<AuditLogModel>> _watchManagerScopedAuditLogs({
    required String companyId,
    required String managerId,
    required String teamId,
    required int limit,
  }) {
    final collection = _auditLogsCollection(companyId);
    final queries = <Query<Map<String, dynamic>>>[
      // Do not order these manager scoped queries here. Combining equality
      // filters with orderBy(createdAt) needs a composite index and caused the
      // mobile dashboard to show a failure state until the index exists. We
      // read a small, scoped batch and sort locally instead.
      collection.where('managerId', isEqualTo: managerId).limit(limit * 2),
      // Legacy/self fallback: older audit logs may have actorId but no
      // managerId/team snapshot. This still stays safe because the rules only
      // allow a manager to read their own actor logs through this query.
      collection.where('actorId', isEqualTo: managerId).limit(limit * 2),
    ];

    if (teamId.isNotEmpty) {
      // Legacy/team fallback: catches logs where teamId exists but managerId was
      // missing during the transition to scoped audit logs.
      queries.add(collection.where('teamId', isEqualTo: teamId).limit(limit * 2));
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
          latest[index] = _mapAuditLogSnapshot(snapshot, companyId, limit * 2);
          emitMerged();
        },
        onError: (_) {
          latest[index] = const <AuditLogModel>[];
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
