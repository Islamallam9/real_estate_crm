import 'package:equatable/equatable.dart';

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
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      userProfile = null,
      message = null,
      errorCode = null;

  final AuthStatus status;
  final AppUser? user;
  final UserProfile? userProfile;
  final String? message;
  final AuthErrorCode? errorCode;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    UserProfile? userProfile,
    String? message,
    AuthErrorCode? errorCode,
    bool clearUser = false,
    bool clearUserProfile = false,
    bool clearMessage = false,
    bool clearErrorCode = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      userProfile: clearUserProfile ? null : userProfile ?? this.userProfile,
      message: clearMessage ? null : message ?? this.message,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [status, user, userProfile, message, errorCode];
}
