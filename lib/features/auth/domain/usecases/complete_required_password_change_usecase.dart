import '../repositories/auth_repository.dart';

class CompleteRequiredPasswordChangeUseCase {
  const CompleteRequiredPasswordChangeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String companyId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.completeRequiredPasswordChange(
      companyId: companyId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
