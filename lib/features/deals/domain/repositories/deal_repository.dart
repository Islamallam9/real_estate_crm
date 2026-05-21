import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../entities/deal.dart';

abstract interface class DealRepository {
  Stream<List<Deal>> watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 40,
  });

  Future<Deal> createDeal({required String companyId, required Deal deal});

  Future<Deal> updateDeal({required String companyId, required Deal deal});

  Future<void> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  });

  Future<void> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
    String reason = '',
  });

  Future<void> restoreDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  });
}
