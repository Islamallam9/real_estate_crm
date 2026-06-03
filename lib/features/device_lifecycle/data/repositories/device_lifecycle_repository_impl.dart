import '../../domain/repositories/device_lifecycle_repository.dart';
import '../datasources/device_lifecycle_remote_data_source.dart';

class DeviceLifecycleRepositoryImpl implements DeviceLifecycleRepository {
  const DeviceLifecycleRepositoryImpl({required this.remoteDataSource});

  final DeviceLifecycleRemoteDataSource remoteDataSource;

  @override
  Future<void> registerCompanyInstall({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required String source,
  }) {
    return remoteDataSource.registerCompanyInstall(
      companyId: companyId,
      uid: uid,
      role: role,
      locale: locale,
      source: source,
    );
  }

  @override
  Future<void> recordHeartbeat({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) {
    return remoteDataSource.recordHeartbeat(
      companyId: companyId,
      uid: uid,
      role: role,
      locale: locale,
    );
  }
}
