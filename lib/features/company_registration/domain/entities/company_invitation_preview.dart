import 'package:equatable/equatable.dart';

class CompanyInvitationPreview extends Equatable {
  const CompanyInvitationPreview({
    required this.valid,
    required this.status,
    required this.planName,
    required this.userLimit,
    required this.storageLimitMb,
    required this.features,
    required this.locale,
    required this.timezone,
    required this.expiresAt,
    required this.allowedAdminEmailHint,
    required this.message,
  });

  final bool valid;
  final String status;
  final String planName;
  final int userLimit;
  final int storageLimitMb;
  final Map<String, bool> features;
  final String locale;
  final String timezone;
  final DateTime? expiresAt;
  final String allowedAdminEmailHint;
  final String message;

  @override
  List<Object?> get props => [
    valid,
    status,
    planName,
    userLimit,
    storageLimitMb,
    features,
    locale,
    timezone,
    expiresAt,
    allowedAdminEmailHint,
    message,
  ];
}

class CompanyRegistrationResult extends Equatable {
  const CompanyRegistrationResult({
    required this.success,
    required this.companyId,
    required this.adminUid,
    this.signedIn = false,
  });

  final bool success;
  final String companyId;
  final String adminUid;
  final bool signedIn;

  @override
  List<Object?> get props => [success, companyId, adminUid, signedIn];
}
