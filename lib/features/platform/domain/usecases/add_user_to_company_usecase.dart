import '../../../../core/constants/role_constants.dart';
import '../repositories/platform_repository.dart';

class AddUserToCompanyUseCase {
  const AddUserToCompanyUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) {
    return _repository.addUserToCompany(
      companyId: companyId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
    );
  }
}
