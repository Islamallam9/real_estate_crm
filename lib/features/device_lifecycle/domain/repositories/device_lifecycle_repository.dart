abstract interface class DeviceLifecycleRepository {
  Future<void> registerCompanyInstall({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required String source,
  });

  Future<void> recordHeartbeat({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  });
}
