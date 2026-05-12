import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class CreateDealUseCase {
  const CreateDealUseCase(this._repository);

  final DealRepository _repository;

  Future<Deal> call({required String companyId, required Deal deal}) {
    return _repository.createDeal(companyId: companyId, deal: deal);
  }
}
