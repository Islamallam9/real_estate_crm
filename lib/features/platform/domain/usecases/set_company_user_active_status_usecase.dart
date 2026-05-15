import '../repositories/platform_repository.dart';

class SetCompanyUserActiveStatusUseCase {
  const SetCompanyUserActiveStatusUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String uid,
    required bool isActive,
  }) {
    return _repository.setCompanyUserActiveStatus(
      companyId: companyId,
      uid: uid,
      isActive: isActive,
    );
  }
}
