import 'package:equatable/equatable.dart';

import '../../data/datasources/company_users_remote_data_source.dart';
import '../../domain/entities/company_crm_user.dart';

enum CompanyUsersStatus { initial, loading, ready, saving, failure }

class CompanyUsersState extends Equatable {
  const CompanyUsersState({
    required this.status,
    required this.users,
    required this.query,
    required this.roleFilter,
    required this.activeFilter,
    this.message,
    this.createdResult,
  });

  const CompanyUsersState.initial()
      : status = CompanyUsersStatus.initial,
        users = const [],
        query = '',
        roleFilter = '',
        activeFilter = null,
        message = null,
        createdResult = null;

  final CompanyUsersStatus status;
  final List<CompanyCrmUser> users;
  final String query;
  final String roleFilter;
  final bool? activeFilter;
  final String? message;
  final CreatedCompanyUserResult? createdResult;

  List<CompanyCrmUser> get filteredUsers {
    final clean = query.trim().toLowerCase();
    return users.where((user) {
      final matchesQuery = clean.isEmpty ||
          user.fullName.toLowerCase().contains(clean) ||
          user.email.toLowerCase().contains(clean) ||
          user.role.toLowerCase().contains(clean) ||
          user.phone.toLowerCase().contains(clean);
      final matchesRole = roleFilter.trim().isEmpty || user.role == roleFilter;
      final matchesActive = activeFilter == null || user.isActive == activeFilter;
      return matchesQuery && matchesRole && matchesActive;
    }).toList();
  }

  CompanyUsersState copyWith({
    CompanyUsersStatus? status,
    List<CompanyCrmUser>? users,
    String? query,
    String? roleFilter,
    bool? activeFilter,
    String? message,
    CreatedCompanyUserResult? createdResult,
    bool clearMessage = false,
    bool clearCreatedResult = false,
    bool clearRoleFilter = false,
    bool clearActiveFilter = false,
  }) {
    return CompanyUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      query: query ?? this.query,
      roleFilter: clearRoleFilter ? '' : roleFilter ?? this.roleFilter,
      activeFilter: clearActiveFilter ? null : activeFilter ?? this.activeFilter,
      message: clearMessage ? null : message ?? this.message,
      createdResult:
          clearCreatedResult ? null : createdResult ?? this.createdResult,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        query,
        roleFilter,
        activeFilter,
        message,
        createdResult,
      ];
}
