import '../repositories/deal_repository.dart';

class RestoreDealUseCase {
  const RestoreDealUseCase(this._repository);

  final DealRepository _repository;

  Future<void> call({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) {
    return _repository.restoreDeal(
      companyId: companyId,
      dealId: dealId,
      updatedBy: updatedBy,
    );
  }
}

