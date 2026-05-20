import '../../domain/entities/platform_invitation.dart';
import '../../domain/repositories/platform_invitation_repository.dart';
import '../datasources/platform_invitations_remote_data_source.dart';

class PlatformInvitationRepositoryImpl
    implements PlatformInvitationRepository {
  const PlatformInvitationRepositoryImpl({required this.remoteDataSource});

  final PlatformInvitationsRemoteDataSource remoteDataSource;

  @override
  Future<CreatedCompanyInvitation> createCompanyInvitation({
    required String planId,
    required String planName,
    required int userLimit,
    required int storageLimitMb,
    required Map<String, bool> features,
    required String locale,
    required String timezone,
    required DateTime expiresAt,
    required String notes,
  }) {
    return remoteDataSource.createCompanyInvitation(
      planId: planId,
      planName: planName,
      userLimit: userLimit,
      storageLimitMb: storageLimitMb,
      features: features,
      locale: locale,
      timezone: timezone,
      expiresAt: expiresAt,
      notes: notes,
    );
  }

  @override
  Future<List<PlatformInvitation>> listCompanyInvitations({String? status}) {
    return remoteDataSource.listCompanyInvitations(status: status);
  }

  @override
  Future<void> revokeCompanyInvitation({required String invitationId}) {
    return remoteDataSource.revokeCompanyInvitation(
      invitationId: invitationId,
    );
  }
}
