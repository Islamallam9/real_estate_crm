import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/error_mapper.dart';
import '../models/company_invitation_preview_model.dart';

abstract interface class CompanyRegistrationRemoteDataSource {
  Future<CompanyInvitationPreviewModel> validateInvitation({
    required String invitationCode,
  });

  Future<CompanyRegistrationResultModel> acceptInvitation({
    required String invitationCode,
    required String companyName,
    required String companySlug,
    required String companyPhone,
    required String companyCity,
    required String companyWebsite,
    required String adminFullName,
    required String adminPhone,
    required String adminEmail,
    required String password,
    required String confirmPassword,
    required String locale,
    required String timezone,
  });
}

class FirebaseCompanyRegistrationRemoteDataSource
    implements CompanyRegistrationRemoteDataSource {
  FirebaseCompanyRegistrationRemoteDataSource({
    FirebaseFunctions? functions,
    FirebaseAuth? firebaseAuth,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<CompanyInvitationPreviewModel> validateInvitation({
    required String invitationCode,
  }) async {
    final data = await _callMap('validateCompanyInvitation', {
      'invitationCode': invitationCode.trim(),
    });
    return CompanyInvitationPreviewModel.fromMap(data);
  }

  @override
  Future<CompanyRegistrationResultModel> acceptInvitation({
    required String invitationCode,
    required String companyName,
    required String companySlug,
    required String companyPhone,
    required String companyCity,
    required String companyWebsite,
    required String adminFullName,
    required String adminPhone,
    required String adminEmail,
    required String password,
    required String confirmPassword,
    required String locale,
    required String timezone,
  }) async {
    final data = await _callMap('acceptCompanyInvitation', {
      'invitationCode': invitationCode.trim(),
      'companyName': companyName.trim(),
      'companySlug': companySlug.trim(),
      'companyPhone': companyPhone.trim(),
      'companyCity': companyCity.trim(),
      'companyWebsite': companyWebsite.trim(),
      'adminFullName': adminFullName.trim(),
      'adminPhone': adminPhone.trim(),
      'adminEmail': adminEmail.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'locale': locale,
      'timezone': timezone.trim(),
    });
    final result = CompanyRegistrationResultModel.fromMap(data);
    var signedIn = false;
    if (result.success) {
      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: adminEmail.trim(),
          password: password,
        );
        signedIn = true;
      } on FirebaseAuthException {
        signedIn = false;
      }
    }
    return CompanyRegistrationResultModel(
      success: result.success,
      companyId: result.companyId,
      adminUid: result.adminUid,
      signedIn: signedIn,
    );
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
      throw CompanyRegistrationException(_registrationErrorKey(error));
    } on FirebaseAuthException catch (error) {
      throw CompanyRegistrationException(_authErrorKey(error));
    } on FirebaseException catch (error) {
      throw CompanyRegistrationException(_firebaseErrorKey(error));
    }
  }
}

class CompanyRegistrationException implements Exception {
  const CompanyRegistrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _registrationErrorKey(FirebaseFunctionsException error) {
  final details = error.details;
  if (details is Map && details['key'] is String) {
    final key = _normalizeRegistrationErrorKey(details['key'] as String);
    if (key != null) {
      return key;
    }
  }

  final message = _stripTechnicalErrorText(error.message);
  final messageKey = _normalizeRegistrationErrorKey(message);
  if (messageKey != null) {
    return messageKey;
  }

  final lower = message.toLowerCase();
  if (lower.contains('failed_precondition') ||
      lower.contains('firebaseautherror') ||
      lower.contains('exception')) {
    return 'unable-to-complete-registration';
  }
  if (lower.contains('admin email') && lower.contains('exist')) {
    return 'admin-email-already-exists';
  }
  if (lower.contains('company') && lower.contains('exist')) {
    return 'company-id-already-exists';
  }
  if (lower.contains('weak') || lower.contains('password')) {
    return 'weak-password';
  }
  if (lower.contains('expired')) return 'invitation-expired';
  if (lower.contains('used')) return 'invitation-used';
  if (lower.contains('revoked')) return 'invitation-revoked';
  if (lower.contains('invitation')) return 'invitation-invalid';

  return switch (error.code) {
    'already-exists' => 'registration-conflict',
    'invalid-argument' => 'unable-to-complete-registration',
    'failed-precondition' => 'unable-to-complete-registration',
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    _ => 'unable-to-complete-registration',
  };
}

String _authErrorKey(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' || 'account-exists-with-different-credential' =>
      'admin-email-already-exists',
    'invalid-email' => 'invalid-admin-email',
    'weak-password' => 'weak-password',
    'operation-not-allowed' => 'email-password-auth-disabled',
    _ => 'unable-to-complete-registration',
  };
}

String _firebaseErrorKey(FirebaseException error) {
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    _ => 'unable-to-complete-registration',
  };
}

String? _normalizeRegistrationErrorKey(String key) {
  final clean = key.trim();
  if (_registrationErrorKeys.contains(clean)) {
    return clean;
  }
  return switch (clean) {
    'registration-already-started-or-conflict' => 'registration-conflict',
    'unable-to-create-workspace' => 'unable-to-create-company',
    _ => null,
  };
}

String _stripTechnicalErrorText(String? message) {
  var text = (message ?? '').trim();
  final prefixes = [
    'Exception: ',
    'FirebaseFunctionsException: ',
    'FirebaseException: ',
    'FirebaseAuthException: ',
  ];
  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        changed = true;
      }
    }
  }
  text = text.replaceFirst(RegExp(r'^\d+\s+FAILED_PRECONDITION:\s*'), '');
  return text.trim();
}

const _registrationErrorKeys = {
  'invitation-invalid',
  'invitation-expired',
  'invitation-used',
  'invitation-revoked',
  'invitation-limit-reached',
  'admin-email-already-exists',
  'company-id-already-exists',
  'invalid-admin-email',
  'weak-password',
  'email-password-auth-disabled',
  'registration-conflict',
  'unable-to-create-admin',
  'unable-to-create-company',
  'unable-to-complete-registration',
};
