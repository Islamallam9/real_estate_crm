import 'package:equatable/equatable.dart';

import 'company_metadata.dart';
import 'user_membership.dart';

class AuthCompanyResolution extends Equatable {
  const AuthCompanyResolution({
    required this.isPlatformAdmin,
    this.membership,
    this.company,
    this.platformFullName = '',
    this.platformPhotoUrl = '',
  });

  final bool isPlatformAdmin;
  final UserMembership? membership;
  final CompanyMetadata? company;
  final String platformFullName;
  final String platformPhotoUrl;

  bool get hasCompany => membership != null && company != null;

  bool get isCompanyActive => company?.isUsable ?? false;

  @override
  List<Object?> get props => [
    isPlatformAdmin,
    membership,
    company,
    platformFullName,
    platformPhotoUrl,
  ];
}
