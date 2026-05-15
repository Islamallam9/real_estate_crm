import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  AppUser? getCurrentUser();

  Stream<AppUser?> authStateChanges();
}
