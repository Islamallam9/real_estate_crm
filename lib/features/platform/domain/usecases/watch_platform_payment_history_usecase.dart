import '../entities/platform_payment_history.dart';
import '../repositories/platform_repository.dart';

class WatchPlatformPaymentHistoryUseCase {
  const WatchPlatformPaymentHistoryUseCase(this._repository);

  final PlatformRepository _repository;

  Stream<List<PlatformPaymentHistory>> call({required String companyId}) {
    return _repository.watchPaymentHistory(companyId: companyId);
  }
}
