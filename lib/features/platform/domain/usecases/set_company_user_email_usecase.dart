import '../repositories/platform_repository.dart';

class SetCompanyUserEmailUseCase {
  const SetCompanyUserEmailUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String uid,
    required String newEmail,
  }) {
    return _repository.setCompanyUserEmail(
      companyId: companyId,
      uid: uid,
      newEmail: newEmail,
    );
  }
}
