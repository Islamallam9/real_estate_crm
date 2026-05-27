import '../entities/platform_invitation.dart';

abstract interface class PlatformInvitationRepository {
  Future<CreatedCompanyInvitation> createCompanyInvitation({
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
  });

  Future<List<PlatformInvitation>> listCompanyInvitations({String? status});

  Future<void> revokeCompanyInvitation({required String invitationId});
}
