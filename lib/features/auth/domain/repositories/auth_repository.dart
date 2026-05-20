import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> completeRequiredPasswordChange({
    required String companyId,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> recordLoginActivity({
    String? companyId,
    required String locale,
    required String timezone,
    required String platform,
    required String browser,
    required String deviceType,
    required String userAgent,
    required String appVersion,
  });

  AppUser? getCurrentUser();

  Stream<AppUser?> authStateChanges();
}
