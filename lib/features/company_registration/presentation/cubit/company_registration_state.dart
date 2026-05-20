import 'package:equatable/equatable.dart';

import '../../domain/entities/company_invitation_preview.dart';

enum CompanyRegistrationStatus {
  initial,
  validating,
  inviteValid,
  inviteInvalid,
  submitting,
  completed,
  failure,
}

class CompanyRegistrationState extends Equatable {
  const CompanyRegistrationState({
    required this.status,
    this.preview,
    this.result,
    this.message,
  });

  const CompanyRegistrationState.initial()
    : this(status: CompanyRegistrationStatus.initial);

  final CompanyRegistrationStatus status;
  final CompanyInvitationPreview? preview;
  final CompanyRegistrationResult? result;
  final String? message;

  CompanyRegistrationState copyWith({
    CompanyRegistrationStatus? status,
    CompanyInvitationPreview? preview,
    CompanyRegistrationResult? result,
    String? message,
    bool clearPreview = false,
    bool clearMessage = false,
  }) {
    return CompanyRegistrationState(
      status: status ?? this.status,
      preview: clearPreview ? null : preview ?? this.preview,
      result: result ?? this.result,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, preview, result, message];
}
