abstract final class FirebasePaths {
  static String platformAdmins() => 'platform_admins';

  static String platformAdmin(String uid) => '${platformAdmins()}/$uid';

  static String globalUsers() => 'users';

  static String globalUser(String uid) => '${globalUsers()}/$uid';

  static String userMemberships(String uid) => '${globalUser(uid)}/memberships';

  static String userMembership({
    required String uid,
    required String companyId,
  }) {
    return '${userMemberships(uid)}/$companyId';
  }

  static String company(String companyId) => 'companies/$companyId';

  static String companyUsers(String companyId) {
    return '${company(companyId)}/users';
  }

  static String companyUser({required String companyId, required String uid}) {
    return '${companyUsers(companyId)}/$uid';
  }

  static String companyLeads(String companyId) {
    return '${company(companyId)}/leads';
  }

  static String companyClients(String companyId) {
    return '${company(companyId)}/clients';
  }

  static String companyProperties(String companyId) {
    return '${company(companyId)}/properties';
  }

  static String companyDeals(String companyId) {
    return '${company(companyId)}/deals';
  }

  static String companyTasks(String companyId) {
    return '${company(companyId)}/tasks';
  }

  static String companyAppointments(String companyId) {
    return '${company(companyId)}/appointments';
  }

  static String companyNotifications(String companyId) {
    return '${company(companyId)}/notifications';
  }

  static String companyAuditLogs(String companyId) {
    return '${company(companyId)}/audit_logs';
  }
}
