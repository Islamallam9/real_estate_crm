abstract interface class NotificationPushTokenRepository {
  Future<String?> currentToken();

  Stream<String> watchTokenRefreshes();

  Future<void> registerCompanyToken({
    required String companyId,
    required String token,
    required String locale,
    required String role,
  });

  Future<void> registerPlatformToken({
    required String token,
    required String locale,
  });

  Future<void> deactivateCompanyToken({
    required String companyId,
    required String token,
  });

  Future<void> deactivatePlatformToken({required String token});
}
