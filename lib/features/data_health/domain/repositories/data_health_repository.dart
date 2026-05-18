import '../../../../core/constants/role_constants.dart';
import '../../../platform/domain/entities/company_data_health_report.dart';
import '../../../users/domain/entities/user_profile.dart';

abstract interface class DataHealthRepository {
  Future<CompanyDataHealthReport> getOperationalReport({
    required String companyId,
  });

  Future<void> backfillSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  });

  Future<void> reassignRecord({
    required String companyId,
    required String module,
    required String recordId,
    required String newAssigneeUid,
  });

  Future<List<UserProfile>> getEligibleAssignees({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  });
}
