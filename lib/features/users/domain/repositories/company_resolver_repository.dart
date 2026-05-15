import '../entities/auth_company_resolution.dart';

abstract interface class CompanyResolverRepository {
  Future<AuthCompanyResolution> resolveForUser({required String uid});
}
