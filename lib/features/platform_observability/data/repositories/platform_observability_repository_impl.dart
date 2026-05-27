import '../../domain/entities/client_error_report.dart';
import '../../domain/entities/platform_error_log.dart';
import '../../domain/repositories/platform_observability_repository.dart';
import '../datasources/platform_observability_remote_data_source.dart';

class PlatformObservabilityRepositoryImpl
    implements PlatformObservabilityRepository {
  const PlatformObservabilityRepositoryImpl({
    required PlatformObservabilityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PlatformObservabilityRemoteDataSource _remoteDataSource;

  @override
  Stream<List<PlatformErrorLog>> watchErrorLogs({int limit = 160}) {
    return _remoteDataSource.watchErrorLogs(limit: limit);
  }

  @override
  Future<void> reportClientError(ClientErrorReport report) {
    return _remoteDataSource.reportClientError(report);
  }

  @override
  Future<void> markResolved({required String logId}) {
    return _remoteDataSource.markResolved(logId: logId);
  }
}
