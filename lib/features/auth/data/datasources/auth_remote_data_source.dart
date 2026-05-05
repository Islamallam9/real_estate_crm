import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/errors/auth_exception.dart';
import '../models/app_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  AppUserModel? getCurrentUser();

  Stream<AppUserModel?> authStateChanges();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          AuthErrorMessages.invalidCredentials,
          code: AuthErrorCode.invalidCredentials,
        );
      }

      return AppUserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  @override
  AppUserModel? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUserModel.fromFirebaseUser(user);
  }

  @override
  Stream<AppUserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }

      return AppUserModel.fromFirebaseUser(user);
    });
  }
}

AuthException _mapFirebaseAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
    case 'user-disabled':
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return const AuthException(
        AuthErrorMessages.invalidCredentials,
        code: AuthErrorCode.invalidCredentials,
      );
    case 'network-request-failed':
      return const AuthException(
        AuthErrorMessages.connection,
        code: AuthErrorCode.connection,
      );
    default:
      return const AuthException(
        AuthErrorMessages.signInFailed,
        code: AuthErrorCode.signInFailed,
      );
  }
}
