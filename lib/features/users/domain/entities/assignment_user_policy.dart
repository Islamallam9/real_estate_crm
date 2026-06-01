import '../../../../core/constants/role_constants.dart';
import 'user_profile.dart';

enum AssignableWorkType {
  lead,
  client,
  property,
  task,
  appointment,
  deal,
  salesOwner,
}

abstract final class AssignmentUserPolicy {
  static bool canOwn(AssignableWorkType type, UserProfile user) {
    if (!user.isActive) {
      return false;
    }

    switch (type) {
      case AssignableWorkType.lead:
        return user.role == UserRole.salesAgent ||
            user.role == UserRole.marketing;
      case AssignableWorkType.task:
        return user.role == UserRole.admin ||
            user.role == UserRole.manager ||
            user.role == UserRole.salesAgent ||
            user.role == UserRole.marketing;
      case AssignableWorkType.appointment:
        return user.role == UserRole.admin ||
            user.role == UserRole.manager ||
            user.role == UserRole.salesAgent ||
            user.role == UserRole.marketing;
      case AssignableWorkType.client:
      case AssignableWorkType.property:
      case AssignableWorkType.deal:
      case AssignableWorkType.salesOwner:
        return user.role == UserRole.salesAgent;
    }
  }

  static List<UserProfile> assignableUsersFor(
    AssignableWorkType type,
    List<UserProfile> users,
  ) {
    return users.where((user) => canOwn(type, user)).toList()
      ..sort(_compareUsersByDisplayName);
  }

  static int _compareUsersByDisplayName(UserProfile a, UserProfile b) {
    final aLabel = a.fullName.trim().isEmpty ? a.email : a.fullName;
    final bLabel = b.fullName.trim().isEmpty ? b.email : b.fullName;
    return aLabel.compareTo(bLabel);
  }
}
