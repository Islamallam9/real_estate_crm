import '../repositories/platform_repository.dart';

class UpdateCompanyPlatformSettingsUseCase {
  const UpdateCompanyPlatformSettingsUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
  }) {
    return _repository.updateCompanyPlatformSettings(
      companyId: companyId,
      name: name,
      displayName: displayName,
      status: status,
      isActive: isActive,
      settings: settings,
      limits: limits,
      features: features,
    );
  }
}
