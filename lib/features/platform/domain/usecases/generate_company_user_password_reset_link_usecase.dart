import '../entities/password_reset_link_result.dart';
import '../repositories/platform_repository.dart';

class GenerateCompanyUserPasswordResetLinkUseCase {
  const GenerateCompanyUserPasswordResetLinkUseCase(this._repository);

  final PlatformRepository _repository;

  Future<PasswordResetLinkResult> call({
    required String companyId,
    required String uid,
  }) {
    return _repository.generateCompanyUserPasswordResetLink(
      companyId: companyId,
      uid: uid,
    );
  }
}
