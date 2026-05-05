import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  AppUser? getCurrentUser();

  Stream<AppUser?> authStateChanges();
}
