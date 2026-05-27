import '../repositories/platform_repository.dart';

class CreateCompanyWithAdminUseCase {
  const CreateCompanyWithAdminUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
    int? trialDays,
    String trialDurationUnit = 'days',
  }) {
    return _repository.createCompanyWithAdmin(
      companyId: companyId,
      companyName: companyName,
      adminFullName: adminFullName,
      adminEmail: adminEmail,
      adminPhone: adminPhone,
      locale: locale,
      timezone: timezone,
      trialDays: trialDays,
      trialDurationUnit: trialDurationUnit,
    );
  }
}
