import 'package:equatable/equatable.dart';

import '../../data/datasources/company_users_remote_data_source.dart';
import '../../domain/entities/company_crm_user.dart';

enum CompanyUsersStatus { initial, loading, ready, saving, failure }

class CompanyUsersState extends Equatable {
  const CompanyUsersState({
    required this.status,
    required this.users,
    required this.query,
    this.message,
    this.createdResult,
  });

  const CompanyUsersState.initial()
      : status = CompanyUsersStatus.initial,
        users = const [],
        query = '',
        message = null,
        createdResult = null;

  final CompanyUsersStatus status;
  final List<CompanyCrmUser> users;
  final String query;
  final String? message;
  final CreatedCompanyUserResult? createdResult;

  List<CompanyCrmUser> get filteredUsers {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return users;
    return users.where((user) {
      return user.fullName.toLowerCase().contains(clean) ||
          user.email.toLowerCase().contains(clean) ||
          user.role.toLowerCase().contains(clean) ||
          user.phone.toLowerCase().contains(clean);
    }).toList();
  }

  CompanyUsersState copyWith({
    CompanyUsersStatus? status,
    List<CompanyCrmUser>? users,
    String? query,
    String? message,
    CreatedCompanyUserResult? createdResult,
    bool clearMessage = false,
    bool clearCreatedResult = false,
  }) {
    return CompanyUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      query: query ?? this.query,
      message: clearMessage ? null : message ?? this.message,
      createdResult:
          clearCreatedResult ? null : createdResult ?? this.createdResult,
    );
  }

  @override
  List<Object?> get props => [status, users, query, message, createdResult];
}
