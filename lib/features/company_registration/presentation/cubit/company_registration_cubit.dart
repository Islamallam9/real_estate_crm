import 'package:bloc/bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/usecases/accept_company_invitation_usecase.dart';
import '../../domain/usecases/validate_company_invitation_usecase.dart';
import 'company_registration_state.dart';

class CompanyRegistrationCubit extends Cubit<CompanyRegistrationState> {
  CompanyRegistrationCubit({
    required ValidateCompanyInvitationUseCase validateInvitationUseCase,
    required AcceptCompanyInvitationUseCase acceptInvitationUseCase,
  }) : _validateInvitationUseCase = validateInvitationUseCase,
       _acceptInvitationUseCase = acceptInvitationUseCase,
       super(const CompanyRegistrationState.initial());

  final ValidateCompanyInvitationUseCase _validateInvitationUseCase;
  final AcceptCompanyInvitationUseCase _acceptInvitationUseCase;

  Future<bool> validateInvitation(String invitationCode) async {
    emit(
      state.copyWith(
        status: CompanyRegistrationStatus.validating,
        clearPreview: true,
        clearMessage: true,
      ),
    );
    try {
      final preview = await _validateInvitationUseCase(
        invitationCode: invitationCode,
      );
      emit(
        state.copyWith(
          status: preview.valid
              ? CompanyRegistrationStatus.inviteValid
              : CompanyRegistrationStatus.inviteInvalid,
          preview: preview,
          message: preview.valid ? null : preview.message,
        ),
      );
      return preview.valid;
    } catch (error) {
      emit(
        state.copyWith(
          status: CompanyRegistrationStatus.failure,
          message: _cleanRegistrationError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> acceptInvitation({
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
    emit(
      state.copyWith(
        status: CompanyRegistrationStatus.submitting,
        clearMessage: true,
      ),
    );
    try {
      final result = await _acceptInvitationUseCase(
        invitationCode: invitationCode,
        companyName: companyName,
        companySlug: companySlug,
        companyPhone: companyPhone,
        companyCity: companyCity,
        companyWebsite: companyWebsite,
        adminFullName: adminFullName,
        adminPhone: adminPhone,
        adminEmail: adminEmail,
        password: password,
        confirmPassword: confirmPassword,
        locale: locale,
        timezone: timezone,
      );
      emit(
        state.copyWith(
          status: CompanyRegistrationStatus.completed,
          result: result,
          clearMessage: true,
        ),
      );
      return result.success;
    } catch (error) {
      emit(
        state.copyWith(
          status: CompanyRegistrationStatus.failure,
          message: _cleanRegistrationError(error),
        ),
      );
      return false;
    }
  }
}

String _cleanRegistrationError(Object error) {
  var text = error.toString().trim();
  const prefixes = [
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
  if (_safeAppErrorMessages.contains(text)) {
    return text;
  }
  final knownKey = _normalizeRegistrationErrorKey(text);
  if (knownKey != null) {
    return knownKey;
  }
  final lower = text.toLowerCase();
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
  return 'unable-to-complete-registration';
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

const _safeAppErrorMessages = {
  AppErrorMessages.unableToConnect,
  AppErrorMessages.permissionDenied,
  AppErrorMessages.unauthenticated,
  AppErrorMessages.unknown,
};
