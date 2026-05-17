import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/profile_image_upload.dart';
import '../../domain/errors/user_profile_exception.dart';
import '../models/user_profile_model.dart';

abstract interface class UserProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile({
    required String companyId,
    required String uid,
  });

  Stream<List<UserProfileModel>> watchActiveUsers({required String companyId});

  Future<UserProfileModel?> updateOwnProfile({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  });

  Future<UserProfileModel?> uploadOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  });

  Future<UserProfileModel?> removeOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  });
}

class FirestoreUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  FirestoreUserProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    firebase_storage.FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storage = storage ?? firebase_storage.FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final firebase_storage.FirebaseStorage _storage;

  static const int _maxProfileImageBytes = 5 * 1024 * 1024;
  static const Duration _storageTimeout = Duration(seconds: 60);
  static const Duration _firestoreTimeout = Duration(seconds: 30);

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
  Stream<List<UserProfileModel>> watchActiveUsers({
    required String companyId,
  }) async* {
    final currentUid = _firebaseAuth.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      yield const [];
      return;
    }

    final currentUser = await getUserProfile(
      companyId: companyId,
      uid: currentUid,
    );

    final usersCollection = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users');

    switch (currentUser.role) {
      case UserRole.admin:
        yield* usersCollection
            .where('isActive', isEqualTo: true)
            .snapshots()
            .map(_activeUsersFromSnapshot(companyId));
        return;
      case UserRole.manager:
        yield* usersCollection
            .where('isActive', isEqualTo: true)
            .where('managerId', isEqualTo: currentUid)
            .snapshots()
            .map(_activeUsersFromSnapshot(companyId));
        return;
      case UserRole.salesAgent:
      case UserRole.marketing:
      case UserRole.viewer:
        yield* usersCollection.doc(currentUid).snapshots().map((snapshot) {
          if (!snapshot.exists) {
            return const <UserProfileModel>[];
          }
          final user = UserProfileModel.fromFirestore(snapshot);
          if (user.companyId != companyId || !user.isActive) {
            return const <UserProfileModel>[];
          }
          return <UserProfileModel>[user];
        });
        return;
    }
  }

  @override
  Future<UserProfileModel?> updateOwnProfile({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  }) async {
    final cleanName = fullName.trim();
    if (uid.trim().isEmpty || cleanName.isEmpty) {
      throw const UserProfileException(AppErrorMessages.unknown);
    }

    try {
      await _firebaseAuth.currentUser?.updateDisplayName(cleanName);
      if (companyId.trim().isEmpty) {
        await _updatePlatformProfile(uid: uid, values: {'fullName': cleanName});
        return null;
      }

      await _companyUserDocument(companyId, uid).update({
        'fullName': cleanName,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }).timeout(_firestoreTimeout);
      return getUserProfile(companyId: companyId, uid: uid);
    } on FirebaseException catch (error) {
      throw UserProfileException(_mapFirestoreError(error));
    } catch (_) {
      throw const UserProfileException('Unable to update your profile.');
    }
  }

  @override
  Future<UserProfileModel?> uploadOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  }) async {
    _validateProfileImage(image);
    final uploadedPath = _profileImageStoragePath(
      companyId: companyId,
      uid: uid,
      fileName: image.fileName,
    );

    try {
      final oldPath = await _currentPhotoStoragePath(
        uid: uid,
        companyId: companyId,
      );
      final ref = _storage.ref().child(uploadedPath);
      await ref
          .putData(
            image.bytes,
            firebase_storage.SettableMetadata(contentType: image.contentType),
          )
          .timeout(_storageTimeout);
      final url = await ref.getDownloadURL().timeout(_firestoreTimeout);
      await _firebaseAuth.currentUser?.updatePhotoURL(url);

      if (companyId.trim().isEmpty) {
        await _updatePlatformProfile(
          uid: uid,
          values: {'photoUrl': url, 'photoStoragePath': uploadedPath},
        );
        await _deleteStoragePath(oldPath);
        return null;
      }

      await _companyUserDocument(companyId, uid).update({
        'photoUrl': url,
        'photoStoragePath': uploadedPath,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }).timeout(_firestoreTimeout);
      await _deleteStoragePath(oldPath);
      return getUserProfile(companyId: companyId, uid: uid);
    } on FirebaseException catch (error) {
      await _deleteStoragePath(uploadedPath);
      throw UserProfileException(_mapFirestoreError(error));
    } on TimeoutException {
      await _deleteStoragePath(uploadedPath);
      throw const UserProfileException(AppErrorMessages.unableToConnect);
    } catch (_) {
      await _deleteStoragePath(uploadedPath);
      throw const UserProfileException('Unable to update your profile image.');
    }
  }

  @override
  Future<UserProfileModel?> removeOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  }) async {
    try {
      final oldPath = await _currentPhotoStoragePath(
        uid: uid,
        companyId: companyId,
      );
      await _firebaseAuth.currentUser?.updatePhotoURL(null);

      if (companyId.trim().isEmpty) {
        await _updatePlatformProfile(
          uid: uid,
          values: {'photoUrl': '', 'photoStoragePath': ''},
        );
        await _deleteStoragePath(oldPath);
        return null;
      }

      await _companyUserDocument(companyId, uid).update({
        'photoUrl': '',
        'photoStoragePath': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }).timeout(_firestoreTimeout);
      await _deleteStoragePath(oldPath);
      return getUserProfile(companyId: companyId, uid: uid);
    } on FirebaseException catch (error) {
      throw UserProfileException(_mapFirestoreError(error));
    } catch (_) {
      throw const UserProfileException('Unable to remove your profile image.');
    }
  }

  DocumentReference<Map<String, dynamic>> _companyUserDocument(
    String companyId,
    String uid,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(uid);
  }

  Future<void> _updatePlatformProfile({
    required String uid,
    required Map<String, dynamic> values,
  }) async {
    final update = <String, dynamic>{
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };
    await _firestore
        .collection('platform_admins')
        .doc(uid)
        .update(update)
        .timeout(_firestoreTimeout);
  }

  Future<String> _currentPhotoStoragePath({
    required String uid,
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) {
      final snapshot = await _firestore
          .collection('platform_admins')
          .doc(uid)
          .get()
          .timeout(_firestoreTimeout);
      return snapshot.data()?['photoStoragePath'] as String? ?? '';
    }

    final snapshot = await _companyUserDocument(companyId, uid)
        .get()
        .timeout(_firestoreTimeout);
    return snapshot.data()?['photoStoragePath'] as String? ?? '';
  }

  Future<void> _deleteStoragePath(String path) async {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) {
      return;
    }
    try {
      await _storage.ref().child(cleanPath).delete().timeout(_storageTimeout);
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }
    } catch (_) {
      return;
    }
  }

  void _validateProfileImage(ProfileImageUpload image) {
    if (!image.contentType.toLowerCase().startsWith('image/')) {
      throw const UserProfileException(AppErrorMessages.propertyImageInvalidType);
    }
    if (image.bytes.lengthInBytes > _maxProfileImageBytes) {
      throw const UserProfileException(AppErrorMessages.propertyImageTooLarge);
    }
  }
}

List<UserProfileModel> Function(QuerySnapshot<Map<String, dynamic>>)
_activeUsersFromSnapshot(String companyId) {
  return (snapshot) {
    final users = snapshot.docs.map(UserProfileModel.fromFirestore).where((
      user,
    ) {
      return user.companyId == companyId && user.isActive;
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return users;
  };
}

String _profileImageStoragePath({
  required String companyId,
  required String uid,
  required String fileName,
}) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final safeName = _safeFileName(fileName);
  if (companyId.trim().isEmpty) {
    return 'platform_admins/$uid/profile/${timestamp}_$safeName';
  }
  return 'companies/$companyId/users/$uid/profile/${timestamp}_$safeName';
}

String _safeFileName(String fileName) {
  final normalized = fileName.split(RegExp(r'[\\/]+')).last.trim();
  final safe = normalized.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (safe.isEmpty) {
    return 'profile_image.jpg';
  }
  return safe;
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
    case 'unauthorized':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
    case 'object-not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    case 'invalid-argument':
      return AppErrorMessages.unknown;
    default:
      return 'Unable to load your user profile.';
  }
}
