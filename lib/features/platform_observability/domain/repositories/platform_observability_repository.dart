import '../entities/client_error_report.dart';
import '../entities/platform_error_log.dart';

abstract interface class PlatformObservabilityRepository {
  Stream<List<PlatformErrorLog>> watchErrorLogs({int limit});

  Future<void> reportClientError(ClientErrorReport report);

  Future<void> markResolved({required String logId});
}
