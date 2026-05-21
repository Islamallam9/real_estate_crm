import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/team.dart';

enum TeamsStatus { initial, loading, ready, saving, failure }

class TeamsState extends Equatable {
  const TeamsState({
    required this.status,
    this.teams = const [],
    this.users = const [],
    this.selectedTeamId,
    this.searchQuery = '',
    this.message,
  });

  const TeamsState.initial() : this(status: TeamsStatus.initial);

  final TeamsStatus status;
  final List<Team> teams;
  final List<UserProfile> users;
  final String? selectedTeamId;
  final String searchQuery;
  final String? message;

  Team? get selectedTeam {
    final id = selectedTeamId;
    if (id != null) {
      for (final team in teams) {
        if (team.id == id) {
          return team;
        }
      }
    }
    return teams.isEmpty ? null : teams.first;
  }

  List<Team> get filteredTeams {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return teams;
    }
    return teams.where((team) {
      return team.name.toLowerCase().contains(query) ||
          team.managerName.toLowerCase().contains(query) ||
          team.managerEmail.toLowerCase().contains(query);
    }).toList();
  }

  List<UserProfile> membersFor(String teamId) {
    return users.where((user) => user.teamId == teamId).toList();
  }

  List<UserProfile> membersForTeam(Team team) {
    final byUid = <String, UserProfile>{};
    for (final user in users) {
      if (user.teamId == team.id || user.managerId == team.managerId) {
        byUid[user.uid] = user;
      }
    }
    return byUid.values.toList();
  }

  List<UserProfile> get managers {
    return users.where((user) => user.role == UserRole.manager).toList();
  }

  TeamsState copyWith({
    TeamsStatus? status,
    List<Team>? teams,
    List<UserProfile>? users,
    String? selectedTeamId,
    String? searchQuery,
    String? message,
    bool clearMessage = false,
    bool clearSelectedTeam = false,
  }) {
    return TeamsState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      users: users ?? this.users,
      selectedTeamId: clearSelectedTeam
          ? null
          : selectedTeamId ?? this.selectedTeamId,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    teams,
    users,
    selectedTeamId,
    searchQuery,
    message,
  ];
}
