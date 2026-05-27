import 'package:equatable/equatable.dart';

class CompanyCrmUser extends Equatable {
  const CompanyCrmUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.teamName,
    required this.managerName,
    this.photoUrl = '',
    this.photoStoragePath = '',
    this.updatedAt,
    this.mustChangePassword = false,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String teamName;
  final String managerName;
  final String photoUrl;
  final String photoStoragePath;
  final DateTime? updatedAt;
  final bool mustChangePassword;

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        phone,
        role,
        isActive,
        teamName,
        managerName,
        photoUrl,
        photoStoragePath,
        updatedAt,
        mustChangePassword,
      ];
}
