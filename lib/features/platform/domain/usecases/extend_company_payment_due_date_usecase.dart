import '../repositories/platform_repository.dart';

class ExtendCompanyPaymentDueDateUseCase {
  const ExtendCompanyPaymentDueDateUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required DateTime nextPaymentDueAt,
    required String notes,
  }) {
    return _repository.extendCompanyPaymentDueDate(
      companyId: companyId,
      nextPaymentDueAt: nextPaymentDueAt,
      notes: notes,
    );
  }
}
