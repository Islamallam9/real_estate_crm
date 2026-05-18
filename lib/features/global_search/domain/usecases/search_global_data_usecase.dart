import '../../../../core/constants/role_constants.dart';
import '../entities/global_search_result.dart';
import '../repositories/global_search_repository.dart';

class SearchGlobalDataUseCase {
  const SearchGlobalDataUseCase(this._repository);

  final GlobalSearchRepository _repository;

  Future<List<GlobalSearchResult>> call({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required String query,
    required bool includeUsers,
    int limitPerModule = 40,
  }) {
    return _repository.search(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      query: query,
      includeUsers: includeUsers,
      limitPerModule: limitPerModule,
    );
  }
}
