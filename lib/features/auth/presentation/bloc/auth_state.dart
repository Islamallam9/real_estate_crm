import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/company_metadata.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_exception.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.userProfile,
    this.message,
    this.errorCode,
    this.isPlatformAdmin = false,
    this.companyMetadata,
    this.lockoutSecondsRemaining = 0,
    this.passwordResetSent = false,
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      userProfile = null,
      message = null,
      errorCode = null,
      isPlatformAdmin = false,
      companyMetadata = null,
      lockoutSecondsRemaining = 0,
      passwordResetSent = false;

  final AuthStatus status;
  final AppUser? user;
  final UserProfile? userProfile;
  final String? message;
  final AuthErrorCode? errorCode;
  final bool isPlatformAdmin;
  final CompanyMetadata? companyMetadata;
  final int lockoutSecondsRemaining;
  final bool passwordResetSent;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    UserProfile? userProfile,
    String? message,
    AuthErrorCode? errorCode,
    bool? isPlatformAdmin,
    CompanyMetadata? companyMetadata,
    int? lockoutSecondsRemaining,
    bool? passwordResetSent,
    bool clearUser = false,
    bool clearUserProfile = false,
    bool clearCompanyMetadata = false,
    bool clearMessage = false,
    bool clearErrorCode = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      userProfile: clearUserProfile ? null : userProfile ?? this.userProfile,
      message: clearMessage ? null : message ?? this.message,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
      isPlatformAdmin: isPlatformAdmin ?? this.isPlatformAdmin,
      companyMetadata: clearCompanyMetadata
          ? null
          : companyMetadata ?? this.companyMetadata,
      lockoutSecondsRemaining:
          lockoutSecondsRemaining ?? this.lockoutSecondsRemaining,
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    userProfile,
    message,
    errorCode,
    isPlatformAdmin,
    companyMetadata,
    lockoutSecondsRemaining,
    passwordResetSent,
  ];
}
