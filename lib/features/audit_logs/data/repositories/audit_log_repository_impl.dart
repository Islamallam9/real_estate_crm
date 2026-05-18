import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_logs_remote_data_source.dart';
import '../models/audit_log_model.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl({required AuditLogsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AuditLogsRemoteDataSource _remoteDataSource;

  @override
  Future<void> createAuditLog({
    required String companyId,
    required AuditLog auditLog,
  }) {
    return _remoteDataSource.createAuditLog(
      companyId: companyId,
      auditLog: AuditLogModel.fromEntity(auditLog),
    );
  }

  @override
  Stream<List<AuditLog>> watchAuditLogs({
    required String companyId,
    String? managerId,
    String? teamId,
    int limit = 20,
  }) {
    return _remoteDataSource.watchAuditLogs(
      companyId: companyId,
      managerId: managerId,
      teamId: teamId,
      limit: limit,
    ).map((logs) => List<AuditLog>.unmodifiable(logs));
  }
}
