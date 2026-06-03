import '../repositories/platform_repository.dart';

class CreatePlatformReleaseRecordUseCase {
  const CreatePlatformReleaseRecordUseCase(this.repository);

  final PlatformRepository repository;

  Future<void> call({
    required String platform,
    required String appVersion,
    required int buildNumber,
    required int minimumSupportedBuildNumber,
    required int latestBuildNumber,
    required String updateUrl,
    required bool enabled,
    required bool releaseReady,
    required String status,
  }) {
    return repository.createPlatformReleaseRecord(
      platform: platform,
      appVersion: appVersion,
      buildNumber: buildNumber,
      minimumSupportedBuildNumber: minimumSupportedBuildNumber,
      latestBuildNumber: latestBuildNumber,
      updateUrl: updateUrl,
      enabled: enabled,
      releaseReady: releaseReady,
      status: status,
    );
  }
}
