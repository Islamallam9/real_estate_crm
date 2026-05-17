import 'package:equatable/equatable.dart';

class PasswordResetLinkResult extends Equatable {
  const PasswordResetLinkResult({
    required this.uid,
    required this.companyId,
    required this.email,
    required this.passwordResetLink,
  });

  final String uid;
  final String companyId;
  final String email;
  final String passwordResetLink;

  @override
  List<Object?> get props => [uid, companyId, email, passwordResetLink];
}
