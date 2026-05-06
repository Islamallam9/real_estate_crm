import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/user_profile_exception.dart';
import '../models/user_profile_model.dart';

abstract interface class UserProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile({
    required String companyId,
    required String uid,
  });

  Stream<List<UserProfileModel>> watchActiveUsers({required String companyId});
}

class FirestoreUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  FirestoreUserProfileRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfileModel> getUserProfile({
    required String companyId,
    required String uid,
  }) async {
    try {
      final document = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(uid)
          .get();

      if (!document.exists) {
        throw const UserProfileException('Unable to load your user profile.');
      }

      return UserProfileModel.fromFirestore(document);
    } on UserProfileException {
      rethrow;
    } on FirebaseException catch (error) {
      throw UserProfileException(_mapFirestoreError(error));
    } catch (_) {
      throw const UserProfileException('Unable to load your user profile.');
    }
  }

  @override
  Stream<List<UserProfileModel>> watchActiveUsers({required String companyId}) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(UserProfileModel.fromFirestore).where((
            user,
          ) {
            return user.companyId == companyId && user.isActive;
          }).toList();
        });
  }
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    default:
      return 'Unable to load your user profile.';
  }
}
