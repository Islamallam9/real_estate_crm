import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

class WatchTeamsUseCase {
  const WatchTeamsUseCase(this._repository);

  final TeamRepository _repository;

  Stream<List<Team>> call({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    return _repository.watchTeams(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    );
  }
}

class WatchTeamUsersUseCase {
  const WatchTeamUsersUseCase(this._repository);

  final TeamRepository _repository;

  Stream<List<UserProfile>> call({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    return _repository.watchTeamUsers(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    );
  }
}

class CreateTeamUseCase {
  const CreateTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  }) {
    return _repository.createTeam(
      companyId: companyId,
      name: name,
      description: description,
      manager: manager,
      actorUid: actorUid,
    );
  }
}

class UpdateTeamUseCase {
  const UpdateTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  }) {
    return _repository.updateTeam(
      team: team,
      name: name,
      description: description,
      manager: manager,
      isActive: isActive,
      actorUid: actorUid,
    );
  }
}

class SetTeamActiveStatusUseCase {
  const SetTeamActiveStatusUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required Team team,
    required bool isActive,
    required String actorUid,
  }) {
    return _repository.setTeamActiveStatus(
      team: team,
      isActive: isActive,
      actorUid: actorUid,
    );
  }
}

class AddUserToTeamUseCase {
  const AddUserToTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required Team team,
    required UserProfile user,
    required String actorUid,
  }) {
    return _repository.addUserToTeam(
      team: team,
      user: user,
      actorUid: actorUid,
    );
  }
}

class RemoveUserFromTeamUseCase {
  const RemoveUserFromTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required UserProfile user,
    required String actorUid,
  }) {
    return _repository.removeUserFromTeam(user: user, actorUid: actorUid);
  }
}


class BackfillTeamAssignedRecordSnapshotsUseCase {
  const BackfillTeamAssignedRecordSnapshotsUseCase(this._repository);

  final TeamRepository _repository;

  Future<void> call({
    required Team team,
    required String actorUid,
  }) {
    return _repository.backfillTeamAssignedRecordSnapshots(
      team: team,
      actorUid: actorUid,
    );
  }
}
