import '../../../app_update/domain/entities/android_release_policy.dart';
import '../repositories/platform_repository.dart';

class GetAndroidReleasePolicyUseCase {
  const GetAndroidReleasePolicyUseCase(this._repository);

  final PlatformRepository _repository;

  Future<AndroidReleasePolicy> call() {
    return _repository.getAndroidReleasePolicy();
  }
}
