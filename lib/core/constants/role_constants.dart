enum UserRole { admin, manager, salesAgent, marketing, viewer }

abstract final class RoleConstants {
  static const admin = 'admin';
  static const manager = 'manager';
  static const salesAgent = 'salesAgent';
  static const marketing = 'marketing';
  static const viewer = 'viewer';

  static UserRole fromValue(String value) {
    switch (value) {
      case admin:
        return UserRole.admin;
      case manager:
        return UserRole.manager;
      case salesAgent:
        return UserRole.salesAgent;
      case marketing:
        return UserRole.marketing;
      case viewer:
        return UserRole.viewer;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported user role.');
    }
  }

  static String toValue(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return admin;
      case UserRole.manager:
        return manager;
      case UserRole.salesAgent:
        return salesAgent;
      case UserRole.marketing:
        return marketing;
      case UserRole.viewer:
        return viewer;
    }
  }
}
