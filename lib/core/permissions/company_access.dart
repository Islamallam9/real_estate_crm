abstract final class CompanyAccess {
  static bool isSameCompany({
    required String userCompanyId,
    required String targetCompanyId,
  }) {
    return userCompanyId.isNotEmpty && userCompanyId == targetCompanyId;
  }

  static bool canAccessCompany({
    required String userCompanyId,
    required String targetCompanyId,
  }) {
    return isSameCompany(
      userCompanyId: userCompanyId,
      targetCompanyId: targetCompanyId,
    );
  }

  static bool canAccessCompanyRecord({
    required String userCompanyId,
    required String recordCompanyId,
  }) {
    return isSameCompany(
      userCompanyId: userCompanyId,
      targetCompanyId: recordCompanyId,
    );
  }
}
