import '../entities/user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile> getUserProfile({
    required String companyId,
    required String uid,
  });

  Stream<List<UserProfile>> watchActiveUsers({required String companyId});
}
