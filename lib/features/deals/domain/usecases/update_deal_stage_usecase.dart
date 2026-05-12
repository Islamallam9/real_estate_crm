import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealStageUseCase {
  const UpdateDealStageUseCase(this._repository);

  final DealRepository _repository;

  Future<void> call({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  }) {
    return _repository.updateDealStage(
      companyId: companyId,
      dealId: dealId,
      stage: stage,
      lostReason: lostReason,
      updatedBy: updatedBy,
    );
  }
}
