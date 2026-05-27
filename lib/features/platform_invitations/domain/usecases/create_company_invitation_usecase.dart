import '../entities/platform_invitation.dart';
import '../repositories/platform_invitation_repository.dart';

class CreateCompanyInvitationUseCase {
  const CreateCompanyInvitationUseCase(this._repository);

  final PlatformInvitationRepository _repository;

  Future<CreatedCompanyInvitation> call({
    required String planId,
    required String planName,
    required int userLimit,
    required int storageLimitMb,
    required Map<String, bool> features,
    required String locale,
    required String timezone,
    required DateTime expiresAt,
    int? trialDays,
    String trialDurationUnit = 'days',
    required String notes,
  }) {
    return _repository.createCompanyInvitation(
      planId: planId,
      planName: planName,
      userLimit: userLimit,
      storageLimitMb: storageLimitMb,
      features: features,
      locale: locale,
      timezone: timezone,
      expiresAt: expiresAt,
      trialDays: trialDays,
      trialDurationUnit: trialDurationUnit,
      notes: notes,
    );
  }
}
