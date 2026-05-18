import '../../../../core/constants/role_constants.dart';
import '../../../platform/domain/entities/company_data_health_report.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/repositories/data_health_repository.dart';
import '../datasources/data_health_remote_data_source.dart';

class DataHealthRepositoryImpl implements DataHealthRepository {
  const DataHealthRepositoryImpl({required DataHealthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final DataHealthRemoteDataSource _remoteDataSource;

  @override
  Future<CompanyDataHealthReport> getOperationalReport({required String companyId}) {
    return _remoteDataSource.getOperationalReport(companyId: companyId);
  }

  @override
  Future<void> backfillSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) {
    return _remoteDataSource.backfillSnapshots(
      companyId: companyId,
      module: module,
      recordId: recordId,
    );
  }

  @override
  Future<void> reassignRecord({
    required String companyId,
    required String module,
    required String recordId,
    required String newAssigneeUid,
  }) {
    return _remoteDataSource.reassignRecord(
      companyId: companyId,
      module: module,
      recordId: recordId,
      newAssigneeUid: newAssigneeUid,
    );
  }

  @override
  Future<List<UserProfile>> getEligibleAssignees({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  }) {
    return _remoteDataSource.getEligibleAssignees(
      companyId: companyId,
      module: module,
      currentRole: currentRole,
      currentUid: currentUid,
      currentTeamId: currentTeamId,
    );
  }
}
