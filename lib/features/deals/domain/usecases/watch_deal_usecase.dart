import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class WatchDealUseCase {
  const WatchDealUseCase(this._repository);

  final DealRepository _repository;

  Stream<Deal?> call({
    required String companyId,
    required String dealId,
  }) {
    return _repository.watchDeal(companyId: companyId, dealId: dealId);
  }
}
