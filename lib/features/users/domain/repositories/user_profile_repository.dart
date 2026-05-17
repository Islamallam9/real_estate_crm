import '../entities/profile_image_upload.dart';
import '../entities/user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile> getUserProfile({
    required String companyId,
    required String uid,
  });

  Stream<List<UserProfile>> watchActiveUsers({required String companyId});

  Future<UserProfile?> updateOwnProfile({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  });

  Future<UserProfile?> uploadOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  });

  Future<UserProfile?> removeOwnProfileImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  });
}
