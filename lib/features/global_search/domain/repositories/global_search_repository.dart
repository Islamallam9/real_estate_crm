import '../../../../core/constants/role_constants.dart';
import '../entities/global_search_result.dart';

abstract interface class GlobalSearchRepository {
  Future<List<GlobalSearchResult>> search({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required String query,
    required bool includeUsers,
    int limitPerModule,
  });
}
