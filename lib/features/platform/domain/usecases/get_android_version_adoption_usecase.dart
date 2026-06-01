import '../entities/android_version_adoption.dart';
import '../repositories/platform_repository.dart';

class GetAndroidVersionAdoptionUseCase {
  const GetAndroidVersionAdoptionUseCase(this._repository);

  final PlatformRepository _repository;

  Future<AndroidVersionAdoptionSummary> call() {
    return _repository.getAndroidVersionAdoption();
  }
}
