import '../repositories/platform_observability_repository.dart';

class MarkPlatformErrorResolvedUseCase {
  const MarkPlatformErrorResolvedUseCase(this._repository);

  final PlatformObservabilityRepository _repository;

  Future<void> call({required String logId}) {
    return _repository.markResolved(logId: logId);
  }
}
