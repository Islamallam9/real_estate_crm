import 'package:equatable/equatable.dart';

import 'company_metadata.dart';
import 'user_membership.dart';

class AuthCompanyResolution extends Equatable {
  const AuthCompanyResolution({
    required this.isPlatformAdmin,
    this.membership,
    this.company,
  });

  final bool isPlatformAdmin;
  final UserMembership? membership;
  final CompanyMetadata? company;

  bool get hasCompany => membership != null && company != null;

  bool get isCompanyActive => company?.isUsable ?? false;

  @override
  List<Object?> get props => [isPlatformAdmin, membership, company];
}
