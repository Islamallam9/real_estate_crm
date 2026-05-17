import '../entities/profile_image_upload.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class UpdateOwnProfileUseCase {
  const UpdateOwnProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile?> call({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  }) {
    return _repository.updateOwnProfile(
      uid: uid,
      companyId: companyId,
      fullName: fullName,
      isPlatformAdmin: isPlatformAdmin,
    );
  }
}

class UploadOwnProfileImageUseCase {
  const UploadOwnProfileImageUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile?> call({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  }) {
    return _repository.uploadOwnProfileImage(
      uid: uid,
      companyId: companyId,
      isPlatformAdmin: isPlatformAdmin,
      image: image,
    );
  }
}

class RemoveOwnProfileImageUseCase {
  const RemoveOwnProfileImageUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile?> call({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  }) {
    return _repository.removeOwnProfileImage(
      uid: uid,
      companyId: companyId,
      isPlatformAdmin: isPlatformAdmin,
    );
  }
}
