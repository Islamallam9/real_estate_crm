import '../entities/company_data_health_report.dart';
import '../repositories/platform_repository.dart';

class GetCompanyDataHealthReportUseCase {
  const GetCompanyDataHealthReportUseCase(this._repository);

  final PlatformRepository _repository;

  Future<CompanyDataHealthReport> call({required String companyId}) {
    return _repository.getCompanyDataHealthReport(companyId: companyId);
  }
}
