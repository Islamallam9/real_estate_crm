import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';
import '../../../users/domain/entities/user_profile.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthLockoutTicked extends AuthEvent {
  const AuthLockoutTicked();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}


final class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated({
    this.profile,
    this.fullName,
    this.photoUrl,
  });

  final UserProfile? profile;
  final String? fullName;
  final String? photoUrl;

  @override
  List<Object?> get props => [profile, fullName, photoUrl];
}
