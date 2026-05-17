import '../repositories/auth_repository.dart';

class RecordLoginActivityUseCase {
  const RecordLoginActivityUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    String? companyId,
    required String locale,
    required String timezone,
    required String platform,
    required String browser,
    required String deviceType,
    required String userAgent,
    required String appVersion,
  }) {
    return _repository.recordLoginActivity(
      companyId: companyId,
      locale: locale,
      timezone: timezone,
      platform: platform,
      browser: browser,
      deviceType: deviceType,
      userAgent: userAgent,
      appVersion: appVersion,
    );
  }
}
