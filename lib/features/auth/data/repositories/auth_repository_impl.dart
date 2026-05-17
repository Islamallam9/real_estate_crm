import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _remoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> recordLoginActivity({
    String? companyId,
    required String locale,
    required String timezone,
    required String platform,
    required String browser,
    required String deviceType,
    required String userAgent,
    required String appVersion,
  }) {
    return _remoteDataSource.recordLoginActivity(
      companyId: companyId,
      locale: locale,
      timezone: timezone,
      platform: platform,
      browser: browser,
      deviceType: deviceType,
      userAgent: userAgent,
      appVersion: appVersion,
    );
  }

  @override
  AppUser? getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }
}
