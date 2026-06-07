import 'package:equatable/equatable.dart';

import '../../domain/entities/company_user_login_activity.dart';

enum CompanyUserLoginActivityStatus { initial, loading, loaded, empty, failure }

class CompanyUserLoginActivityState extends Equatable {
  const CompanyUserLoginActivityState({
    required this.status,
    required this.activities,
    this.message,
  });

  const CompanyUserLoginActivityState.initial()
      : status = CompanyUserLoginActivityStatus.initial,
        activities = const <CompanyUserLoginActivity>[],
        message = null;

  final CompanyUserLoginActivityStatus status;
  final List<CompanyUserLoginActivity> activities;
  final String? message;

  CompanyUserLoginActivityState copyWith({
    CompanyUserLoginActivityStatus? status,
    List<CompanyUserLoginActivity>? activities,
    String? message,
    bool clearMessage = false,
  }) {
    return CompanyUserLoginActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, activities, message];
}
