import '../repositories/deal_repository.dart';

class ArchiveDealUseCase {
  const ArchiveDealUseCase(this._repository);

  final DealRepository _repository;

  Future<void> call({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) {
    return _repository.archiveDeal(
      companyId: companyId,
      dealId: dealId,
      updatedBy: updatedBy,
    );
  }
}
