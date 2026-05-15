import '../repositories/platform_repository.dart';

class SetCompanyActiveStatusUseCase {
  const SetCompanyActiveStatusUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({required String companyId, required bool isActive}) {
    return _repository.setCompanyActiveStatus(
      companyId: companyId,
      isActive: isActive,
    );
  }
}
