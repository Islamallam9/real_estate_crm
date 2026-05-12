import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealUseCase {
  const UpdateDealUseCase(this._repository);

  final DealRepository _repository;

  Future<Deal> call({required String companyId, required Deal deal}) {
    return _repository.updateDeal(companyId: companyId, deal: deal);
  }
}
