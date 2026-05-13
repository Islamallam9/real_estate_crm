import '../entities/audit_log.dart';

abstract interface class AuditLogRepository {
  Future<void> createAuditLog({
    required String companyId,
    required AuditLog auditLog,
  });

  Stream<List<AuditLog>> watchAuditLogs({
    required String companyId,
    int limit,
  });
}
