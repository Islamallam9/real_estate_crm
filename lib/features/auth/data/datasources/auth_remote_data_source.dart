import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/auth_exception.dart';
import '../models/app_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

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

  AppUserModel? getCurrentUser();

  Stream<AppUserModel?> authStateChanges();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _functions;

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
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) {
      throw const AuthException(
        AppErrorMessages.unauthenticated,
        code: AuthErrorCode.profileMissing,
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw _mapPasswordChangeError(error);
    }
  }

  @override
  Future<void> completeRequiredPasswordChange({
    required String companyId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    try {
      await _functions.httpsCallable('completeRequiredPasswordChange').call({
        'companyId': companyId.trim(),
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthException(
        error.message ?? AuthErrorMessages.passwordChangeFailed,
        code: AuthErrorCode.unknown,
      );
    } on FirebaseException catch (error) {
      throw _mapFirebaseAuthError(
        FirebaseAuthException(code: error.code, message: error.message),
      );
    }
  }

  @override
  Future<void> recordLoginActivity({
    String? companyId,
    required String locale,
    required String timezone,
    required String platform,
    required String browser,
    required String deviceType,
    required String userAgent,
    required String appVersion,
  }) async {
    try {
      await _functions.httpsCallable('recordLoginActivity').call({
        if ((companyId ?? '').trim().isNotEmpty) 'companyId': companyId!.trim(),
        'locale': locale,
        'timezone': timezone,
        'platform': platform,
        'browser': browser,
        'deviceType': deviceType,
        'userAgent': userAgent,
        'appVersion': appVersion,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthException(
        error.message ?? AppErrorMessages.unknown,
        code: AuthErrorCode.unknown,
      );
    } on FirebaseException catch (error) {
      throw _mapFirebaseAuthError(
        FirebaseAuthException(code: error.code, message: error.message),
      );
    }
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
    return _firebaseAuth.idTokenChanges().map((user) {
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
    case 'unavailable':
    case 'deadline-exceeded':
      return const AuthException(
        AppErrorMessages.unableToConnect,
        code: AuthErrorCode.connection,
      );
    case 'permission-denied':
    case 'unauthenticated':
      return const AuthException(
        AppErrorMessages.unauthenticated,
        code: AuthErrorCode.profileMissing,
      );
    default:
      return const AuthException(
        AuthErrorMessages.signInFailed,
        code: AuthErrorCode.signInFailed,
      );
  }
}

AuthException _mapPasswordChangeError(FirebaseAuthException error) {
  switch (error.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return const AuthException(
        AuthErrorMessages.currentPasswordIncorrect,
        code: AuthErrorCode.invalidCredentials,
      );
    case 'requires-recent-login':
    case 'user-token-expired':
      return const AuthException(
        AuthErrorMessages.recentLoginRequired,
        code: AuthErrorCode.profileMissing,
      );
    case 'weak-password':
      return const AuthException(
        AuthErrorMessages.weakPassword,
        code: AuthErrorCode.unknown,
      );
    case 'network-request-failed':
    case 'unavailable':
    case 'deadline-exceeded':
      return const AuthException(
        AppErrorMessages.unableToConnect,
        code: AuthErrorCode.connection,
      );
    default:
      return const AuthException(
        AuthErrorMessages.passwordChangeFailed,
        code: AuthErrorCode.unknown,
      );
  }
}
