import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class WatchActiveUsersUseCase {
  const WatchActiveUsersUseCase(this._repository);

  final UserProfileRepository _repository;

  Stream<List<UserProfile>> call({required String companyId}) {
    return _repository.watchActiveUsers(companyId: companyId);
  }
}
