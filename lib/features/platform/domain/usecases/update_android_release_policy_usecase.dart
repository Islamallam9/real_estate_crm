import '../repositories/platform_repository.dart';

class UpdateAndroidReleasePolicyUseCase {
  const UpdateAndroidReleasePolicyUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required bool enabled,
    required bool releaseReady,
    required int minimumSupportedBuildNumber,
    required int latestBuildNumber,
    required String updateUrl,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
  }) {
    return _repository.updateAndroidReleasePolicy(
      enabled: enabled,
      releaseReady: releaseReady,
      minimumSupportedBuildNumber: minimumSupportedBuildNumber,
      latestBuildNumber: latestBuildNumber,
      updateUrl: updateUrl,
      titleEn: titleEn,
      titleAr: titleAr,
      bodyEn: bodyEn,
      bodyAr: bodyAr,
    );
  }
}
