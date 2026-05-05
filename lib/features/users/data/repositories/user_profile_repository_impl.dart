import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_data_source.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({
    required UserProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final UserProfileRemoteDataSource _remoteDataSource;

  @override
  Future<UserProfile> getUserProfile({
    required String companyId,
    required String uid,
  }) {
    return _remoteDataSource.getUserProfile(companyId: companyId, uid: uid);
  }

  @override
  Stream<List<UserProfile>> watchActiveUsers({required String companyId}) {
    return _remoteDataSource.watchActiveUsers(companyId: companyId);
  }
}
