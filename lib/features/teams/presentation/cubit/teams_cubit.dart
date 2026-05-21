import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/team.dart';
import '../../domain/errors/team_exception.dart';
import '../../domain/usecases/team_usecases.dart';
import 'teams_state.dart';

class TeamsCubit extends Cubit<TeamsState> {
  TeamsCubit({
    required WatchTeamsUseCase watchTeamsUseCase,
    required WatchTeamUsersUseCase watchTeamUsersUseCase,
    required CreateTeamUseCase createTeamUseCase,
    required UpdateTeamUseCase updateTeamUseCase,
    required SetTeamActiveStatusUseCase setTeamActiveStatusUseCase,
    required AddUserToTeamUseCase addUserToTeamUseCase,
    required RemoveUserFromTeamUseCase removeUserFromTeamUseCase,
    required BackfillTeamAssignedRecordSnapshotsUseCase backfillTeamAssignedRecordSnapshotsUseCase,
  }) : _watchTeamsUseCase = watchTeamsUseCase,
       _watchTeamUsersUseCase = watchTeamUsersUseCase,
       _createTeamUseCase = createTeamUseCase,
       _updateTeamUseCase = updateTeamUseCase,
       _setTeamActiveStatusUseCase = setTeamActiveStatusUseCase,
       _addUserToTeamUseCase = addUserToTeamUseCase,
       _removeUserFromTeamUseCase = removeUserFromTeamUseCase,
       _backfillTeamAssignedRecordSnapshotsUseCase = backfillTeamAssignedRecordSnapshotsUseCase,
       super(const TeamsState.initial());

  final WatchTeamsUseCase _watchTeamsUseCase;
  final WatchTeamUsersUseCase _watchTeamUsersUseCase;
  final CreateTeamUseCase _createTeamUseCase;
  final UpdateTeamUseCase _updateTeamUseCase;
  final SetTeamActiveStatusUseCase _setTeamActiveStatusUseCase;
  final AddUserToTeamUseCase _addUserToTeamUseCase;
  final RemoveUserFromTeamUseCase _removeUserFromTeamUseCase;
  final BackfillTeamAssignedRecordSnapshotsUseCase
      _backfillTeamAssignedRecordSnapshotsUseCase;

  StreamSubscription? _teamsSubscription;
  StreamSubscription? _usersSubscription;

  void watch({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    emit(state.copyWith(status: TeamsStatus.loading, clearMessage: true));
    _teamsSubscription?.cancel();
    _usersSubscription?.cancel();

    _teamsSubscription = _watchTeamsUseCase(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    ).listen(
      (teams) {
        final selectedId = state.selectedTeamId;
        final nextSelected = selectedId != null &&
                teams.any((team) => team.id == selectedId)
            ? selectedId
            : (teams.isEmpty ? null : teams.first.id);
        emit(
          state.copyWith(
            status: TeamsStatus.ready,
            teams: teams,
            selectedTeamId: nextSelected,
            clearMessage: true,
            clearSelectedTeam: nextSelected == null,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: TeamsStatus.failure,
            message: _teamErrorMessage(error),
          ),
        );
      },
    );

    _usersSubscription = _watchTeamUsersUseCase(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
    ).listen(
      (users) {
        emit(
          state.copyWith(
            status: state.status == TeamsStatus.loading
                ? TeamsStatus.ready
                : state.status,
            users: users,
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: TeamsStatus.failure,
            message: _teamErrorMessage(error),
          ),
        );
      },
    );
  }

  void selectTeam(String teamId) {
    emit(state.copyWith(selectedTeamId: teamId, clearMessage: true));
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, clearMessage: true));
  }

  Future<bool> createTeam({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  }) {
    return _save(() {
      return _createTeamUseCase(
        companyId: companyId,
        name: name,
        description: description,
        manager: manager,
        actorUid: actorUid,
      );
    });
  }

  Future<bool> updateTeam({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  }) {
    return _save(() {
      return _updateTeamUseCase(
        team: team,
        name: name,
        description: description,
        manager: manager,
        isActive: isActive,
        actorUid: actorUid,
      );
    });
  }

  Future<bool> setTeamActiveStatus({
    required Team team,
    required bool isActive,
    required String actorUid,
  }) {
    return _save(() {
      return _setTeamActiveStatusUseCase(
        team: team,
        isActive: isActive,
        actorUid: actorUid,
      );
    });
  }

  Future<bool> addUserToTeam({
    required Team team,
    required UserProfile user,
    required String actorUid,
  }) {
    return _save(() {
      return _addUserToTeamUseCase(
        team: team,
        user: user,
        actorUid: actorUid,
      );
    });
  }

  Future<bool> removeUserFromTeam({
    required UserProfile user,
    required String actorUid,
  }) {
    return _save(() {
      return _removeUserFromTeamUseCase(user: user, actorUid: actorUid);
    });
  }

  Future<bool> backfillTeamAssignedRecordSnapshots({
    required Team team,
    required String actorUid,
  }) {
    return _save(() {
      return _backfillTeamAssignedRecordSnapshotsUseCase(
        team: team,
        actorUid: actorUid,
      );
    });
  }

  Future<bool> _save(Future<void> Function() action) async {
    emit(state.copyWith(status: TeamsStatus.saving, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(status: TeamsStatus.ready, clearMessage: true));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: TeamsStatus.failure,
          message: _teamErrorMessage(error),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _teamsSubscription?.cancel();
    _usersSubscription?.cancel();
    return super.close();
  }
}

String _teamErrorMessage(Object error) {
  if (error is TeamException) {
    return error.message;
  }

  final text = error.toString().toLowerCase();
  if (text.contains('permission-denied') || text.contains('permission denied')) {
    return TeamErrorMessages.permissionDenied;
  }
  if (text.contains('unauthenticated')) {
    return TeamErrorMessages.unauthenticated;
  }
  if (text.contains('not-found') || text.contains('not found')) {
    return TeamErrorMessages.userNotFound;
  }
  if (text.contains('unavailable') ||
      text.contains('network') ||
      text.contains('deadline-exceeded') ||
      text.contains('timeout')) {
    return TeamErrorMessages.connection;
  }
  return TeamErrorMessages.unknown;
}
