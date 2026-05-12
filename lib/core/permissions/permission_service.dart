import '../constants/role_constants.dart';
import 'app_permission.dart';
import 'company_access.dart';
import 'data_scope.dart';

abstract final class PermissionService {
  static bool can(UserRole role, AppPermission permission) {
    return permissionsFor(role).contains(permission);
  }

  static bool canWithinCompany({
    required UserRole role,
    required AppPermission permission,
    required String userCompanyId,
    required String targetCompanyId,
  }) {
    return CompanyAccess.canAccessCompany(
          userCompanyId: userCompanyId,
          targetCompanyId: targetCompanyId,
        ) &&
        can(role, permission);
  }

  static bool canAccessRecord({
    required UserRole role,
    required AppPermission permission,
    required String userCompanyId,
    required String recordCompanyId,
  }) {
    return CompanyAccess.canAccessCompanyRecord(
          userCompanyId: userCompanyId,
          recordCompanyId: recordCompanyId,
        ) &&
        can(role, permission);
  }

  static Set<AppPermission> permissionsFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return _adminPermissions;
      case UserRole.manager:
        return _managerPermissions;
      case UserRole.salesAgent:
        return _salesAgentPermissions;
      case UserRole.marketing:
        return _marketingPermissions;
      case UserRole.viewer:
        return _viewerPermissions;
    }
  }

  static DataScope dataScopeFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return DataScope.companyWide;
      case UserRole.manager:
        return DataScope.teamWide;
      case UserRole.salesAgent:
        return DataScope.assignedOnly;
      case UserRole.marketing:
        return DataScope.assignedOnly;
      case UserRole.viewer:
        return DataScope.readOnly;
    }
  }

  static bool hasCompanyWideAccess(UserRole role) {
    return dataScopeFor(role) == DataScope.companyWide;
  }

  static bool hasTeamWideAccess(UserRole role) {
    final scope = dataScopeFor(role);
    return scope == DataScope.companyWide || scope == DataScope.teamWide;
  }

  static bool isAssignedOnly(UserRole role) {
    return dataScopeFor(role) == DataScope.assignedOnly;
  }

  static bool isReadOnly(UserRole role) {
    return dataScopeFor(role) == DataScope.readOnly;
  }
}

const _adminPermissions = <AppPermission>{
  AppPermission.viewDashboard,
  AppPermission.viewUsers,
  AppPermission.manageUsers,
  AppPermission.viewLeads,
  AppPermission.createLead,
  AppPermission.editLead,
  AppPermission.deleteLead,
  AppPermission.archiveLead,
  AppPermission.assignLead,
  AppPermission.viewProperties,
  AppPermission.createProperty,
  AppPermission.editProperty,
  AppPermission.deleteProperty,
  AppPermission.viewClients,
  AppPermission.createClient,
  AppPermission.editClient,
  AppPermission.archiveClient,
  AppPermission.viewDeals,
  AppPermission.createDeal,
  AppPermission.editDeal,
  AppPermission.archiveDeal,
  AppPermission.viewReports,
  AppPermission.viewTasks,
  AppPermission.createTask,
};

const _managerPermissions = <AppPermission>{
  AppPermission.viewDashboard,
  AppPermission.viewUsers,
  AppPermission.viewLeads,
  AppPermission.createLead,
  AppPermission.editLead,
  AppPermission.assignLead,
  AppPermission.archiveLead,
  AppPermission.viewProperties,
  AppPermission.createProperty,
  AppPermission.editProperty,
  AppPermission.viewClients,
  AppPermission.createClient,
  AppPermission.editClient,
  AppPermission.archiveClient,
  AppPermission.viewDeals,
  AppPermission.createDeal,
  AppPermission.editDeal,
  AppPermission.archiveDeal,
  AppPermission.viewReports,
  AppPermission.viewTasks,
  AppPermission.createTask,
};

const _salesAgentPermissions = <AppPermission>{
  AppPermission.viewDashboard,
  AppPermission.viewLeads,
  AppPermission.createLead,
  AppPermission.editLead,
  AppPermission.viewProperties,
  AppPermission.viewClients,
  AppPermission.viewDeals,
  AppPermission.viewReports,
  AppPermission.viewTasks,
};

const _marketingPermissions = <AppPermission>{
  AppPermission.viewDashboard,
  AppPermission.viewLeads,
  AppPermission.createLead,
  AppPermission.editLead,
  AppPermission.viewProperties,
  AppPermission.viewTasks,
};

const _viewerPermissions = <AppPermission>{
  AppPermission.viewDashboard,
  AppPermission.viewUsers,
  AppPermission.viewLeads,
  AppPermission.viewProperties,
  AppPermission.viewClients,
  AppPermission.viewDeals,
  AppPermission.viewReports,
  AppPermission.viewTasks,
};
