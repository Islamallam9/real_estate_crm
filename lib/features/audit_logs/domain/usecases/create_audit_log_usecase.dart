import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

class CreateAuditLogUseCase {
  const CreateAuditLogUseCase(this._repository);

  final AuditLogRepository _repository;

  Future<void> call({
    required String companyId,
    required AuditLog auditLog,
  }) {
    return _repository.createAuditLog(
      companyId: companyId,
      auditLog: auditLog,
    );
  }
}
