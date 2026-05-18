import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/auth_company_resolution.dart';
import '../../domain/errors/user_profile_exception.dart';
import '../models/company_metadata_model.dart';
import '../models/user_membership_model.dart';

abstract interface class CompanyResolverRemoteDataSource {
  Future<AuthCompanyResolution> resolveForUser({required String uid});
}

class FirestoreCompanyResolverRemoteDataSource
    implements CompanyResolverRemoteDataSource {
  FirestoreCompanyResolverRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<AuthCompanyResolution> resolveForUser({required String uid}) async {
    try {
      final platformAdminFuture = _firestore
          .doc(FirebasePaths.platformAdmin(uid))
          .get();
      final membershipsFuture = _firestore
          .collection(FirebasePaths.userMemberships(uid))
          .get();

      final platformAdminDocument = await platformAdminFuture;
      final platformAdminData = platformAdminDocument.data();
      final isPlatformAdmin =
          platformAdminDocument.exists &&
          (platformAdminData?['isActive'] as bool? ?? false);
      final platformFullName = isPlatformAdmin
          ? (platformAdminData?['fullName'] as String? ?? '')
          : '';
      final platformPhotoUrl = isPlatformAdmin
          ? (platformAdminData?['photoUrl'] as String? ?? '')
          : '';

      final membershipsSnapshot = await membershipsFuture;
      final memberships =
          membershipsSnapshot.docs
              .map(UserMembershipModel.fromFirestore)
              .where((membership) {
                return membership.companyId.trim().isNotEmpty &&
                    membership.isUsable;
              })
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (memberships.isEmpty) {
        return AuthCompanyResolution(
          isPlatformAdmin: isPlatformAdmin,
          platformFullName: platformFullName,
          platformPhotoUrl: platformPhotoUrl,
        );
      }

      final membership = memberships.first;
      final companyDocument = await _firestore
          .doc(FirebasePaths.company(membership.companyId))
          .get();

      if (!companyDocument.exists) {
        return AuthCompanyResolution(
          isPlatformAdmin: isPlatformAdmin,
          membership: membership,
          platformFullName: platformFullName,
          platformPhotoUrl: platformPhotoUrl,
        );
      }

      return AuthCompanyResolution(
        isPlatformAdmin: isPlatformAdmin,
        membership: membership,
        company: CompanyMetadataModel.fromFirestore(companyDocument),
        platformFullName: platformFullName,
        platformPhotoUrl: platformPhotoUrl,
      );
    } on FirebaseException catch (error) {
      throw UserProfileException(_mapFirestoreError(error));
    } catch (_) {
      throw const UserProfileException('Unable to resolve your company access.');
    }
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
    default:
      return 'Unable to resolve your company access.';
  }
}
