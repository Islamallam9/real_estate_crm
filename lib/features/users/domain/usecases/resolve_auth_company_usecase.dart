import '../entities/auth_company_resolution.dart';
import '../repositories/company_resolver_repository.dart';

class ResolveAuthCompanyUseCase {
  const ResolveAuthCompanyUseCase(this._repository);

  final CompanyResolverRepository _repository;

  Future<AuthCompanyResolution> call({required String uid}) {
    return _repository.resolveForUser(uid: uid);
  }
}
