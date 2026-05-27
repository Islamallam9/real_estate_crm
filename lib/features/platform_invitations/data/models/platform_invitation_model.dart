import '../../domain/entities/platform_invitation.dart';

class PlatformInvitationModel extends PlatformInvitation {
  const PlatformInvitationModel({
    required super.id,
    required super.invitationCode,
    required super.codePreview,
    required super.type,
    required super.status,
    required super.planId,
    required super.planName,
    required super.userLimit,
    required super.storageLimitMb,
    required super.features,
    required super.locale,
    required super.timezone,
    required super.allowedAdminEmailHint,
    required super.expiresAt,
    required super.createdAt,
    required super.createdBy,
    required super.acceptedAt,
    required super.acceptedBy,
    required super.acceptedAdminEmail,
    required super.companyId,
    required super.adminUid,
    required super.companyName,
    required super.companyStatus,
    required super.companyPlanName,
    required super.companyCreatedAt,
  });

  factory PlatformInvitationModel.fromMap(Map<String, dynamic> data) {
    return PlatformInvitationModel(
      id: data['id'] as String? ?? '',
      invitationCode:
          (data['invitationCode'] as String?) ??
          (data['codePreview'] as String?) ??
          '',
      codePreview:
          (data['codePreview'] as String?) ??
          (data['invitationCode'] as String?) ??
          '',
      type: data['type'] as String? ?? 'companyAdmin',
      status: data['status'] as String? ?? 'active',
      planId: data['planId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      userLimit: (data['userLimit'] as num?)?.toInt() ?? 0,
      storageLimitMb: (data['storageLimitMb'] as num?)?.toInt() ?? 0,
      features: _boolMap(data['features']),
      locale: data['locale'] as String? ?? 'en',
      timezone: data['timezone'] as String? ?? 'Africa/Cairo',
      allowedAdminEmailHint: data['allowedAdminEmailHint'] as String? ?? '',
      expiresAt: _dateFromValue(data['expiresAt']),
      createdAt: _dateFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      acceptedAt: _dateFromValue(data['acceptedAt']),
      acceptedBy: data['acceptedBy'] as String? ?? '',
      acceptedAdminEmail: data['acceptedAdminEmail'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      adminUid: data['adminUid'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      companyStatus: data['companyStatus'] as String? ?? '',
      companyPlanName: data['companyPlanName'] as String? ?? '',
      companyCreatedAt: _dateFromValue(data['companyCreatedAt']),
    );
  }
}

class CreatedCompanyInvitationModel extends CreatedCompanyInvitation {
  const CreatedCompanyInvitationModel({
    required super.invitationId,
    required super.invitationCode,
    required super.invitationLink,
    required super.codePreview,
    required super.expiresAt,
  });

  factory CreatedCompanyInvitationModel.fromMap(Map<String, dynamic> data) {
    return CreatedCompanyInvitationModel(
      invitationId: data['invitationId'] as String? ?? '',
      invitationCode: data['invitationCode'] as String? ?? '',
      invitationLink: data['invitationLink'] as String? ?? '',
      codePreview: data['codePreview'] as String? ?? '',
      expiresAt: _dateFromValue(data['expiresAt']),
    );
  }
}

Map<String, bool> _boolMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) {
      return MapEntry(key.toString(), value == true);
    });
  }
  return const {};
}

DateTime? _dateFromValue(Object? value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}
