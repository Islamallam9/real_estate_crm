import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/global_search_result.dart';
import '../../domain/repositories/global_search_repository.dart';
import '../datasources/global_search_remote_data_source.dart';

class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  const GlobalSearchRepositoryImpl({required this.remoteDataSource});

  final GlobalSearchRemoteDataSource remoteDataSource;

  @override
  Future<List<GlobalSearchResult>> search({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required String query,
    required bool includeUsers,
    int limitPerModule = 40,
  }) {
    return remoteDataSource.search(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      query: query,
      includeUsers: includeUsers,
      limitPerModule: limitPerModule,
    );
  }
}
