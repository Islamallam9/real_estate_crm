import '../repositories/platform_repository.dart';

class UpdateCompanyPaymentStatusUseCase {
  const UpdateCompanyPaymentStatusUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String paymentStatus,
    DateTime? nextPaymentDueAt,
    DateTime? gracePeriodEndsAt,
    String? suspendedReason,
    String? notes,
  }) {
    return _repository.updateCompanyPaymentStatus(
      companyId: companyId,
      paymentStatus: paymentStatus,
      nextPaymentDueAt: nextPaymentDueAt,
      gracePeriodEndsAt: gracePeriodEndsAt,
      suspendedReason: suspendedReason,
      notes: notes,
    );
  }
}
