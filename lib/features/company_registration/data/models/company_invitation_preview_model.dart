import '../../domain/entities/company_invitation_preview.dart';

class CompanyInvitationPreviewModel extends CompanyInvitationPreview {
  const CompanyInvitationPreviewModel({
    required super.valid,
    required super.status,
    required super.planName,
    required super.userLimit,
    required super.storageLimitMb,
    required super.features,
    required super.locale,
    required super.timezone,
    required super.expiresAt,
    required super.allowedAdminEmailHint,
    required super.message,
  });

  factory CompanyInvitationPreviewModel.fromMap(Map<String, dynamic> data) {
    return CompanyInvitationPreviewModel(
      valid: data['valid'] == true,
      status: data['status'] as String? ?? 'invalid',
      planName: data['planName'] as String? ?? '',
      userLimit: (data['userLimit'] as num?)?.toInt() ?? 0,
      storageLimitMb: (data['storageLimitMb'] as num?)?.toInt() ?? 0,
      features: _boolMap(data['features']),
      locale: data['locale'] as String? ?? 'en',
      timezone: data['timezone'] as String? ?? 'Africa/Cairo',
      expiresAt: _dateFromValue(data['expiresAt']),
      allowedAdminEmailHint: data['allowedAdminEmailHint'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }
}

class CompanyRegistrationResultModel extends CompanyRegistrationResult {
  const CompanyRegistrationResultModel({
    required super.success,
    required super.companyId,
    required super.adminUid,
    super.signedIn,
  });

  factory CompanyRegistrationResultModel.fromMap(Map<String, dynamic> data) {
    return CompanyRegistrationResultModel(
      success: data['success'] == true,
      companyId: data['companyId'] as String? ?? '',
      adminUid: data['adminUid'] as String? ?? '',
      signedIn: data['signedIn'] == true,
    );
  }
}

Map<String, bool> _boolMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value == true));
  }
  return const {};
}

DateTime? _dateFromValue(Object? value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}
