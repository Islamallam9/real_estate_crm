import '../../../../core/constants/role_constants.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class WatchDealsUseCase {
  const WatchDealsUseCase(this._repository);

  final DealRepository _repository;

  Stream<List<Deal>> call({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    int limit = 40,
  }) {
    return _repository.watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      limit: limit,
    );
  }
}
