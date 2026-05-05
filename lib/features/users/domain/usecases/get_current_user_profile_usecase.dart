import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetCurrentUserProfileUseCase {
  const GetCurrentUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile> call({required String companyId, required String uid}) {
    return _repository.getUserProfile(companyId: companyId, uid: uid);
  }
}
