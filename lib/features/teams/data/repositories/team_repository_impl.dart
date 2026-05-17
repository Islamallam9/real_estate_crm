import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_data_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  const TeamRepositoryImpl({required TeamRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TeamRemoteDataSource _remoteDataSource;

  @override
  Stream<List<Team>> watchTeams({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    return _remoteDataSource.watchTeams(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    );
  }

  @override
  Stream<List<UserProfile>> watchTeamUsers({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    return _remoteDataSource.watchTeamUsers(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<void> createTeam({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  }) {
    return _remoteDataSource.createTeam(
      companyId: companyId,
      name: name,
      description: description,
      manager: manager,
      actorUid: actorUid,
    );
  }

  @override
  Future<void> updateTeam({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  }) {
    return _remoteDataSource.updateTeam(
      team: team,
      name: name,
      description: description,
      manager: manager,
      isActive: isActive,
      actorUid: actorUid,
    );
  }

  @override
  Future<void> setTeamActiveStatus({
    required Team team,
    required bool isActive,
    required String actorUid,
  }) {
    return _remoteDataSource.setTeamActiveStatus(
      team: team,
      isActive: isActive,
      actorUid: actorUid,
    );
  }

  @override
  Future<void> addUserToTeam({
    required Team team,
    required UserProfile user,
    required String actorUid,
  }) {
    return _remoteDataSource.addUserToTeam(
      team: team,
      user: user,
      actorUid: actorUid,
    );
  }

  @override
  Future<void> removeUserFromTeam({
    required UserProfile user,
    required String actorUid,
  }) {
    return _remoteDataSource.removeUserFromTeam(user: user, actorUid: actorUid);
  }
}
