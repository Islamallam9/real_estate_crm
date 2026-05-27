import '../entities/client_error_report.dart';
import '../repositories/platform_observability_repository.dart';

class ReportClientErrorUseCase {
  const ReportClientErrorUseCase(this._repository);

  final PlatformObservabilityRepository _repository;

  Future<void> call(ClientErrorReport report) {
    return _repository.reportClientError(report);
  }
}
