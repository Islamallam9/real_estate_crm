import '../../domain/entities/profile_image_upload.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_data_source.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({
    required UserProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final UserProfileRemoteDataSource _remoteDataSource;

  @override
  Future<UserProfile> getUserProfile({
    required String companyId,
    required String uid,
  }) {
    return _remoteDataSource.getUserProfile(companyId: companyId, uid: uid);
  }

  @override
  Stream<List<UserProfile>> watchActiveUsers({required String companyId}) {
    return _remoteDataSource.watchActiveUsers(companyId: companyId);
  }

  @override
  Future<UserProfile?> updateOwnProfile({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  }) {
    return _remoteDataSource.updateOwnProfile(
      uid: uid,
      companyId: companyId,
      fullName: fullName,
      isPlatformAdmin: isPlatformAdmin,
    );
  }

  @override
  Future<UserProfile?> uploadOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  }) {
    return _remoteDataSource.uploadOwnProfileImage(
      uid: uid,
      companyId: companyId,
      isPlatformAdmin: isPlatformAdmin,
      image: image,
    );
  }

  @override
  Future<UserProfile?> removeOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  }) {
    return _remoteDataSource.removeOwnProfileImage(
      uid: uid,
      companyId: companyId,
      isPlatformAdmin: isPlatformAdmin,
    );
  }
}
