import 'package:equatable/equatable.dart';

class PlatformInvitation extends Equatable {
  const PlatformInvitation({
    required this.id,
    required this.invitationCode,
    required this.codePreview,
    required this.type,
    required this.status,
    required this.planId,
    required this.planName,
    required this.userLimit,
    required this.storageLimitMb,
    required this.features,
    required this.locale,
    required this.timezone,
    required this.allowedAdminEmailHint,
    required this.expiresAt,
    required this.createdAt,
    required this.createdBy,
    required this.acceptedAt,
    required this.acceptedBy,
    required this.acceptedAdminEmail,
    required this.companyId,
    required this.adminUid,
    required this.companyName,
    required this.companyStatus,
    required this.companyPlanName,
    required this.companyCreatedAt,
  });

  final String id;
  final String invitationCode;
  final String codePreview;
  final String type;
  final String status;
  final String planId;
  final String planName;
  final int userLimit;
  final int storageLimitMb;
  final Map<String, bool> features;
  final String locale;
  final String timezone;
  final String allowedAdminEmailHint;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? acceptedAt;
  final String acceptedBy;
  final String acceptedAdminEmail;
  final String companyId;
  final String adminUid;
  final String companyName;
  final String companyStatus;
  final String companyPlanName;
  final DateTime? companyCreatedAt;

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
    id,
    invitationCode,
    codePreview,
    type,
    status,
    planId,
    planName,
    userLimit,
    storageLimitMb,
    features,
    locale,
    timezone,
    allowedAdminEmailHint,
    expiresAt,
    createdAt,
    createdBy,
    acceptedAt,
    acceptedBy,
    acceptedAdminEmail,
    companyId,
    adminUid,
    companyName,
    companyStatus,
    companyPlanName,
    companyCreatedAt,
  ];
}

class CreatedCompanyInvitation extends Equatable {
  const CreatedCompanyInvitation({
    required this.invitationId,
    required this.invitationCode,
    required this.invitationLink,
    required this.codePreview,
    required this.expiresAt,
  });

  final String invitationId;
  final String invitationCode;
  final String invitationLink;
  final String codePreview;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [
    invitationId,
    invitationCode,
    invitationLink,
    codePreview,
    expiresAt,
  ];
}
