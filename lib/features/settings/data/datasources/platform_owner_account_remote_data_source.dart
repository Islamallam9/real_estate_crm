import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/errors/error_mapper.dart';

class PlatformOwnerAccountException implements Exception {
  const PlatformOwnerAccountException(this.message);

  final String message;
}

abstract interface class PlatformOwnerAccountRemoteDataSource {
  Future<void> updateEmail({required String uid, required String email});
}

class FirebasePlatformOwnerAccountRemoteDataSource
    implements PlatformOwnerAccountRemoteDataSource {
  FirebasePlatformOwnerAccountRemoteDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _functions;

  @override
  Future<void> updateEmail({required String uid, required String email}) async {
    final cleanEmail = email.trim();
    final currentUser = _firebaseAuth.currentUser;
    if (uid.trim().isEmpty ||
        cleanEmail.isEmpty ||
        currentUser == null ||
        currentUser.uid != uid) {
      throw const PlatformOwnerAccountException(
        AppErrorMessages.permissionDenied,
      );
    }

    try {
      await _functions.httpsCallable('setPlatformOwnerEmail').call({
        'uid': uid,
        'email': cleanEmail,
      });
      await currentUser.reload();
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw PlatformOwnerAccountException(_mapAuthError(error));
    } on FirebaseFunctionsException catch (error) {
      throw PlatformOwnerAccountException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw PlatformOwnerAccountException(_mapFirebaseError(error));
    } catch (_) {
      throw const PlatformOwnerAccountException(AppErrorMessages.unknown);
    }
  }
}

String _mapAuthError(firebase_auth.FirebaseAuthException error) {
  return switch (error.code) {
    'requires-recent-login' => 'requires-recent-login',
    'email-already-in-use' => 'email-already-in-use',
    'invalid-email' => 'invalid-email',
    'network-request-failed' => AppErrorMessages.unableToConnect,
    _ => AppErrorMessages.unknown,
  };
}

String _mapFunctionsError(FirebaseFunctionsException error) {
  return switch (error.code) {
    'already-exists' => 'email-already-in-use',
    'invalid-argument' => 'invalid-email',
    'permission-denied' || 'unauthenticated' => AppErrorMessages.permissionDenied,
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    _ => error.message ?? AppErrorMessages.unknown,
  };
}

String _mapFirebaseError(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
      AppErrorMessages.unableToConnect,
    _ => AppErrorMessages.unknown,
  };
}
