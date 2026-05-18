import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../users/data/models/company_metadata_model.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../domain/entities/password_reset_link_result.dart';
import '../../domain/entities/platform_company_user.dart';
import '../models/company_data_health_report_model.dart';
import '../models/platform_company_user_model.dart';

abstract interface class PlatformRemoteDataSource {
  Stream<List<CompanyMetadata>> watchCompanies();

  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  });

  Future<void> createCompanyWithAdmin({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
  });

  Future<void> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  });

  Future<void> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  });

  Future<void> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  });

  Future<void> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  });

  Future<void> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  });

  Future<PasswordResetLinkResult> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  });

  Future<void> updateCompanyPlatformSettings({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
  });

  Future<CompanyDataHealthReportModel> getCompanyDataHealthReport({
    required String companyId,
  });

  Future<void> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  });
}

class FirebasePlatformRemoteDataSource implements PlatformRemoteDataSource {
  FirebasePlatformRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CompanyMetadata>> watchCompanies() {
    return _firestore
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(CompanyMetadataModel.fromFirestore).toList();
        });
  }

  @override
  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  }) {
    return _firestore
        .collection(FirebasePaths.companyUsers(companyId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(PlatformCompanyUserModel.fromFirestore)
              .where((user) => user.companyId == companyId)
              .toList();
        });
  }

  @override
  Future<void> createCompanyWithAdmin({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
  }) async {
    await _call('createCompanyWithAdmin', {
      'companyId': companyId,
      'companyName': companyName,
      'adminFullName': adminFullName,
      'adminEmail': adminEmail,
      'adminPhone': adminPhone,
      'locale': locale,
      'timezone': timezone,
    });
  }

  @override
  Future<void> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    await _call('addUserToCompany', {
      'companyId': companyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': RoleConstants.toValue(role),
    });
  }

  @override
  Future<void> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  }) async {
    await _call('setCompanyActiveStatus', {
      'companyId': companyId,
      'isActive': isActive,
    });
  }

  @override
  Future<void> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) async {
    await _call('setCompanyUserActiveStatus', {
      'companyId': companyId,
      'uid': uid,
      'isActive': isActive,
    });
  }

  @override
  Future<void> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  }) async {
    await _call('setCompanyUserPassword', {
      'companyId': companyId,
      'uid': uid,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  }) async {
    await _call('setCompanyUserEmail', {
      'companyId': companyId,
      'uid': uid,
      'newEmail': newEmail,
    });
  }

  @override
  Future<PasswordResetLinkResult> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  }) async {
    final data = await _callMap('generateCompanyUserPasswordResetLink', {
      'companyId': companyId,
      'uid': uid,
    });
    return PasswordResetLinkResult(
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      passwordResetLink: data['passwordResetLink'] as String? ?? '',
    );
  }

  @override
  Future<void> updateCompanyPlatformSettings({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
  }) async {
    await _call('updateCompanyPlatformSettings', {
      'companyId': companyId,
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (status != null) 'status': status,
      if (isActive != null) 'isActive': isActive,
      if (settings != null) 'settings': settings,
      if (limits != null) 'limits': limits,
      if (features != null) 'features': features,
    });
  }

  @override
  Future<CompanyDataHealthReportModel> getCompanyDataHealthReport({
    required String companyId,
  }) async {
    final data = await _callMap('getCompanyDataHealthReport', {
      'companyId': companyId,
    });
    return CompanyDataHealthReportModel.fromMap(data);
  }

  @override
  Future<void> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) async {
    await _call('backfillAssignedRecordSnapshots', {
      'companyId': companyId,
      'module': module,
      'recordId': recordId,
    });
  }

  Future<void> _call(String name, Map<String, Object?> data) async {
    await _callMap(name, data);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? AppErrorMessages.permissionDenied);
    } on FirebaseException catch (error) {
      throw Exception(_mapFirebaseError(error));
    }
  }
}

String _mapFirebaseError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
    case 'unauthenticated':
      return AppErrorMessages.permissionDenied;
    default:
      return AppErrorMessages.unknown;
  }
}
