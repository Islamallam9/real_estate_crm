import '../entities/platform_error_log.dart';
import '../repositories/platform_observability_repository.dart';

class WatchPlatformErrorLogsUseCase {
  const WatchPlatformErrorLogsUseCase(this._repository);

  final PlatformObservabilityRepository _repository;

  Stream<List<PlatformErrorLog>> call({int limit = 160}) {
    return _repository.watchErrorLogs(limit: limit);
  }
}
