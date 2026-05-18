import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../repositories/data_health_repository.dart';

class GetDataHealthEligibleAssigneesUseCase {
  const GetDataHealthEligibleAssigneesUseCase(this._repository);

  final DataHealthRepository _repository;

  Future<List<UserProfile>> call({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  }) {
    return _repository.getEligibleAssignees(
      companyId: companyId,
      module: module,
      currentRole: currentRole,
      currentUid: currentUid,
      currentTeamId: currentTeamId,
    );
  }
}
