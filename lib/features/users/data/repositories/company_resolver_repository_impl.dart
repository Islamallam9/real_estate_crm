import '../../domain/entities/auth_company_resolution.dart';
import '../../domain/repositories/company_resolver_repository.dart';
import '../datasources/company_resolver_remote_data_source.dart';

class CompanyResolverRepositoryImpl implements CompanyResolverRepository {
  const CompanyResolverRepositoryImpl({
    required CompanyResolverRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CompanyResolverRemoteDataSource _remoteDataSource;

  @override
  Future<AuthCompanyResolution> resolveForUser({required String uid}) {
    return _remoteDataSource.resolveForUser(uid: uid);
  }
}
