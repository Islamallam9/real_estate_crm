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
      createdAt: auditLog.createdAt,
      metadata: auditLog.metadata,
    );

    await document.set(logToSave.toFirestore());
  }

  @override
  Stream<List<AuditLogModel>> watchAuditLogs({
    required String companyId,
    int limit = 20,
  }) {
    return _auditLogsCollection(companyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        final auditLog = AuditLogModel.fromFirestore(document);
        if (auditLog.companyId != companyId) {
          throw StateError('Audit log company mismatch.');
        }
        return auditLog;
      }).toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _auditLogsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyAuditLogs(companyId));
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
