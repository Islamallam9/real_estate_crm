import '../../../platform/domain/entities/company_data_health_report.dart';
import '../repositories/data_health_repository.dart';

class GetOperationalDataHealthReportUseCase {
  const GetOperationalDataHealthReportUseCase(this._repository);

  final DataHealthRepository _repository;

  Future<CompanyDataHealthReport> call({required String companyId}) {
    return _repository.getOperationalReport(companyId: companyId);
  }
}
