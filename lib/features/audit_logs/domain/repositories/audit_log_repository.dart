import '../entities/audit_log.dart';

abstract interface class AuditLogRepository {
  Future<void> createAuditLog({
    required String companyId,
    required AuditLog auditLog,
  });

  Stream<List<AuditLog>> watchAuditLogs({
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
