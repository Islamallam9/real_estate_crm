import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../platform/data/models/company_data_health_report_model.dart';
import '../../../platform/domain/entities/company_data_health_report.dart';
import '../../../users/data/models/user_profile_model.dart';

abstract interface class DataHealthRemoteDataSource {
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

  Future<void> notifyManager({
    required String companyId,
    required String module,
    required String recordId,
    required String issueType,
  });

  Future<List<UserProfileModel>> getEligibleAssignees({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  });
}

class FirebaseDataHealthRemoteDataSource implements DataHealthRemoteDataSource {
  FirebaseDataHealthRemoteDataSource({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<CompanyDataHealthReport> getOperationalReport({
    required String companyId,
  }) async {
    final result = await _functions
        .httpsCallable('getOperationalDataHealthReport')
        .call(<String, Object?>{'companyId': companyId});
    return CompanyDataHealthReportModel.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  @override
  Future<void> backfillSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) async {
    await _functions.httpsCallable('backfillAssignedRecordSnapshots').call(
      <String, Object?>{
        'companyId': companyId,
        'module': module,
        'recordId': recordId,
      },
    );
  }

  @override
  Future<void> reassignRecord({
    required String companyId,
    required String module,
    required String recordId,
    required String newAssigneeUid,
  }) async {
    await _functions.httpsCallable('reassignDataHealthRecord').call(
      <String, Object?>{
        'companyId': companyId,
        'module': module,
        'recordId': recordId,
        'newAssigneeUid': newAssigneeUid,
      },
    );
  }

  @override
  Future<void> notifyManager({
    required String companyId,
    required String module,
    required String recordId,
    required String issueType,
  }) async {
    await _functions.httpsCallable('notifyDataHealthManager').call(
      <String, Object?>{
        'companyId': companyId,
        'module': module,
        'recordId': recordId,
        'issueType': issueType,
      },
    );
  }

  @override
  Future<List<UserProfileModel>> getEligibleAssignees({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .where('isActive', isEqualTo: true);

    if (currentRole == UserRole.manager) {
      query = query.where('managerId', isEqualTo: currentUid);
    }

    final snapshot = await query.get();
    final allowedRoles = _allowedRolesForModule(module);
    final users = snapshot.docs
        .map(UserProfileModel.fromFirestore)
        .where((user) {
          if (user.companyId != companyId || !user.isActive) {
            return false;
          }
          if (!allowedRoles.contains(user.role)) {
            return false;
          }
          if (currentRole == UserRole.manager) {
            return user.managerId == currentUid ||
                (currentTeamId.isNotEmpty && user.teamId == currentTeamId);
          }
          return currentRole == UserRole.admin;
        })
        .toList();
    users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return users;
  }
}

Set<UserRole> _allowedRolesForModule(String module) {
  switch (module) {
    case 'leads':
    case 'tasks':
      return {UserRole.salesAgent, UserRole.marketing};
    case 'clients':
    case 'deals':
    case 'properties':
      return {UserRole.salesAgent};
    default:
      return const <UserRole>{};
  }
}
