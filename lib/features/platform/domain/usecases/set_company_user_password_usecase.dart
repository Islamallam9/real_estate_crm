import '../repositories/platform_repository.dart';

class SetCompanyUserPasswordUseCase {
  const SetCompanyUserPasswordUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String uid,
    required String newPassword,
  }) {
    return _repository.setCompanyUserPassword(
      companyId: companyId,
      uid: uid,
      newPassword: newPassword,
    );
  }
}
