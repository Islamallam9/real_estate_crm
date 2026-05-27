import '../repositories/platform_repository.dart';

class MarkCompanyPaymentPaidUseCase {
  const MarkCompanyPaymentPaidUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required double amount,
    required String currency,
    required DateTime paymentDate,
    required DateTime nextPaymentDueAt,
    required String paymentCycle,
    required String notes,
  }) {
    return _repository.markCompanyPaymentPaid(
      companyId: companyId,
      amount: amount,
      currency: currency,
      paymentDate: paymentDate,
      nextPaymentDueAt: nextPaymentDueAt,
      paymentCycle: paymentCycle,
      notes: notes,
    );
  }
}
