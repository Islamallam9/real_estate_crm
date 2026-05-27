import 'package:real_estate_crm/features/auth/domain/entities/app_user.dart';
import 'package:real_estate_crm/features/auth/presentation/bloc/auth_state.dart';
import 'package:real_estate_crm/features/users/domain/entities/user_profile.dart';

class ProtectedCompanySession {
  const ProtectedCompanySession({
    required this.user,
    required this.profile,
  });

  final AppUser user;
  final UserProfile profile;

  String get uid => user.uid;
  String get companyId => profile.companyId.trim();

  String scopeKey(String prefix, {bool includeTeamScope = true}) {
    final parts = <String>[
      prefix,
      companyId,
      uid,
      profile.role.name,
    ];
    if (includeTeamScope) {
      parts
        ..add(profile.teamId.trim())
        ..add(profile.managerId.trim());
    }
    return parts.join(':');
  }
}

extension ProtectedCompanySessionAuthState on AuthState {
  ProtectedCompanySession? get protectedCompanySession {
    if (status != AuthStatus.authenticated) {
      return null;
    }

    final currentUser = user;
    final currentProfile = userProfile;
    if (currentUser == null || currentProfile == null) {
      return null;
    }
    if (currentProfile.uid != currentUser.uid) {
      return null;
    }
    if (!currentProfile.isActive) {
      return null;
    }
    if (currentProfile.companyId.trim().isEmpty) {
      return null;
    }
    final currentCompany = companyMetadata;
    if (currentCompany == null ||
        currentCompany.id.trim() != currentProfile.companyId.trim() ||
        !currentCompany.isUsable) {
      return null;
    }

    return ProtectedCompanySession(
      user: currentUser,
      profile: currentProfile,
    );
  }

  bool get isWaitingForProtectedCompanySession {
    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return true;
    }
    if (status != AuthStatus.authenticated) {
      return false;
    }

    final currentUser = user;
    final currentProfile = userProfile;
    final currentCompany = companyMetadata;
    return currentUser != null &&
        (currentProfile == null ||
            currentProfile.uid != currentUser.uid ||
            currentCompany == null ||
            currentCompany.id.trim() != currentProfile.companyId.trim());
  }
}
