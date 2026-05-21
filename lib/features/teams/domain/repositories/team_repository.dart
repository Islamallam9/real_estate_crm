import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../entities/team.dart';

abstract interface class TeamRepository {
  Stream<List<Team>> watchTeams({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  });

  Stream<List<UserProfile>> watchTeamUsers({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  });

  Future<void> createTeam({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  });

  Future<void> updateTeam({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  });

  Future<void> setTeamActiveStatus({
    required Team team,
    required bool isActive,
    required String actorUid,
  });

  Future<void> addUserToTeam({
    required Team team,
    required UserProfile user,
    required String actorUid,
  });

  Future<void> removeUserFromTeam({
    required UserProfile user,
    required String actorUid,
  });

  Future<void> backfillTeamAssignedRecordSnapshots({
    required Team team,
    required String actorUid,
  });
}
