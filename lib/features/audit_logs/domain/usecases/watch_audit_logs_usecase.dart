import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

class WatchAuditLogsUseCase {
  const WatchAuditLogsUseCase(this._repository);

  final AuditLogRepository _repository;

  Stream<List<AuditLog>> call({
    required String companyId,
    int limit = 20,
  }) {
    return _repository.watchAuditLogs(
      companyId: companyId,
      limit: limit,
    );
  }
}
