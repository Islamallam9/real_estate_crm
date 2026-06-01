import '../../../../core/constants/role_constants.dart';
import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/deal.dart';
import '../../domain/repositories/deal_repository.dart';
import '../datasources/deals_remote_data_source.dart';
import '../models/deal_model.dart';

class DealRepositoryImpl implements DealRepository {
  const DealRepositoryImpl({required DealsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final DealsRemoteDataSource _remoteDataSource;

  @override
  Stream<List<Deal>> watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 40,
  }) {
    return _remoteDataSource.watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      limit: limit,
    );
  }

  @override
  Future<Deal> createDeal({required String companyId, required Deal deal}) {
    return _remoteDataSource.createDeal(
      companyId: companyId,
      deal: DealModel.fromEntity(deal),
    );
  }

  @override
  Future<Deal> updateDeal({required String companyId, required Deal deal}) {
    return _remoteDataSource.updateDeal(
      companyId: companyId,
      deal: DealModel.fromEntity(deal),
    );
  }

  @override
  Future<void> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  }) {
    return _remoteDataSource.updateDealStage(
      companyId: companyId,
      dealId: dealId,
      stage: stage,
      lostReason: lostReason,
      updatedBy: updatedBy,
    );
  }

  @override
  Future<void> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
    String reason = '',
  }) {
    return _remoteDataSource.archiveDeal(
      companyId: companyId,
      dealId: dealId,
      updatedBy: updatedBy,
      reason: reason,
    );
  }

  @override
  Future<void> restoreDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) {
    return _remoteDataSource.restoreDeal(
      companyId: companyId,
      dealId: dealId,
      updatedBy: updatedBy,
    );
  }
}
