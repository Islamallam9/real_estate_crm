import '../../domain/repositories/notification_push_token_repository.dart';
import '../datasources/notification_push_token_remote_data_source.dart';

class NotificationPushTokenRepositoryImpl
    implements NotificationPushTokenRepository {
  const NotificationPushTokenRepositoryImpl({required this.remoteDataSource});

  final NotificationPushTokenRemoteDataSource remoteDataSource;

  @override
  Future<String?> currentToken() => remoteDataSource.currentToken();

  @override
  Stream<String> watchTokenRefreshes() => remoteDataSource.watchTokenRefreshes();

  @override
  Future<void> registerCompanyToken({
    required String companyId,
    required String token,
    required String locale,
    required String role,
  }) {
    return remoteDataSource.registerCompanyToken(
      companyId: companyId,
      token: token,
      locale: locale,
      role: role,
    );
  }

  @override
  Future<void> registerPlatformToken({
    required String token,
    required String locale,
  }) {
    return remoteDataSource.registerPlatformToken(token: token, locale: locale);
  }

  @override
  Future<void> deactivateCompanyToken({
    required String companyId,
    required String token,
  }) {
    return remoteDataSource.deactivateCompanyToken(
      companyId: companyId,
      token: token,
    );
  }

  @override
  Future<void> deactivatePlatformToken({required String token}) {
    return remoteDataSource.deactivatePlatformToken(token: token);
  }
}
