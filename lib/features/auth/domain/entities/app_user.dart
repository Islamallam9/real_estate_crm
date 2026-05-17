import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.companyId,
    this.role,
    this.fullName,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? companyId;
  final UserRole? role;
  final String? fullName;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? companyId,
    UserRole? role,
    String? fullName,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      companyId: companyId ?? this.companyId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        companyId,
        role,
        fullName,
      ];
}
