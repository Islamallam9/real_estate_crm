import '../../../../core/constants/role_constants.dart';
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
    int limit = 40,
  }) {
    return _remoteDataSource.watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
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
  }) {
    return _remoteDataSource.archiveDeal(
      companyId: companyId,
      dealId: dealId,
      updatedBy: updatedBy,
    );
  }
}
