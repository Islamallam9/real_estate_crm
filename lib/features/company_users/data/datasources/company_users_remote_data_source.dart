import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/company_crm_user.dart';

class CreatedCompanyUserResult {
  const CreatedCompanyUserResult({
    required this.uid,
    required this.resetLink,
    this.usedTemporaryPassword = false,
  });

  final String uid;
  final String resetLink;
  final bool usedTemporaryPassword;
}

abstract interface class CompanyUsersRemoteDataSource {
  Stream<List<CompanyCrmUser>> watchUsers({required String companyId});

  Future<CreatedCompanyUserResult> addUser({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? temporaryPassword,
  });

  Future<String> generateSetupLink({
    required String companyId,
    required String uid,
  });

  Future<void> setUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  });
}

class FirebaseCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  FirebaseCompanyUsersRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CompanyCrmUser>> watchUsers({required String companyId}) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CompanyCrmUser(
          uid: data['uid'] as String? ?? doc.id,
          fullName: data['fullName'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          role: data['role'] as String? ?? '',
          isActive: data['isActive'] as bool? ?? false,
          teamName: data['teamName'] as String? ?? '',
          managerName: data['managerName'] as String? ?? '',
          mustChangePassword: data['mustChangePassword'] as bool? ?? false,
        );
      }).toList();
    });
  }

  @override
  Future<CreatedCompanyUserResult> addUser({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? temporaryPassword,
  }) async {
    try {
      final result = await _functions.httpsCallable('addUserToCompany').call({
        'companyId': companyId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        if ((temporaryPassword ?? '').trim().isNotEmpty)
          'temporaryPassword': temporaryPassword!.trim(),
      });
      final data = result.data;
      if (data is Map) {
        return CreatedCompanyUserResult(
          uid: data['uid'] as String? ?? '',
          resetLink: data['passwordResetLink'] as String? ?? '',
          usedTemporaryPassword: data['usedTemporaryPassword'] as bool? ?? false,
        );
      }
      return const CreatedCompanyUserResult(uid: '', resetLink: '');
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_mapCompanyUserFunctionError(error));
    } on FirebaseException catch (error) {
      throw Exception(_mapCompanyUserFirebaseError(error));
    }
  }

  @override
  Future<String> generateSetupLink({
    required String companyId,
    required String uid,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('generateCompanyUserPasswordResetLink')
          .call({
        'companyId': companyId,
        'uid': uid,
      });
      final data = result.data;
      if (data is Map) {
        return data['passwordResetLink'] as String? ?? '';
      }
      return '';
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_mapCompanyUserFunctionError(error));
    } on FirebaseException catch (error) {
      throw Exception(_mapCompanyUserFirebaseError(error));
    }
  }

  @override
  Future<void> setUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) async {
    try {
      await _functions.httpsCallable('setCompanyUserActiveStatus').call({
        'companyId': companyId,
        'uid': uid,
        'isActive': isActive,
      });
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_mapCompanyUserFunctionError(error));
    } on FirebaseException catch (error) {
      throw Exception(_mapCompanyUserFirebaseError(error));
    }
  }
}

String _mapCompanyUserFunctionError(FirebaseFunctionsException error) {
  final message = (error.message ?? '').trim();
  if (message == 'Company user already exists.') {
    return 'company-user-already-exists';
  }
  if (message == 'Company user limit reached.') {
    return 'company-user-limit-reached';
  }
  if (message.contains('platform owner support') ||
      message.contains('company admins') ||
      message.contains('deactivate your own')) {
    return AppErrorMessages.permissionDenied;
  }
  if (message.contains('User Management is disabled')) {
    return 'user-management-disabled';
  }
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    'not-found' => AppErrorMessages.notFound,
    'already-exists' => 'company-user-already-exists',
    'failed-precondition' => AppErrorMessages.unknown,
    'invalid-argument' => AppErrorMessages.unknown,
    _ => AppErrorMessages.unknown,
  };
}

String _mapCompanyUserFirebaseError(FirebaseException error) {
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    'not-found' => AppErrorMessages.notFound,
    _ => AppErrorMessages.unknown,
  };
}
