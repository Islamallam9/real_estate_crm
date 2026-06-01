import '../../features/users/domain/entities/company_metadata.dart';
import '../routing/route_names.dart';

enum CompanyFeature {
  leads('leads'),
  clients('clients'),
  properties('properties'),
  tasks('tasks'),
  appointments('appointments'),
  deals('deals'),
  reports('reports'),
  exports('exports'),
  auditLogs('auditLogs'),
  notifications('notifications'),
  userManagement('userManagement');

  const CompanyFeature(this.key);

  final String key;
}

extension CompanyFeatureAccess on CompanyMetadata? {
  bool isFeatureEnabled(CompanyFeature feature) {
    final company = this;
    if (company == null) {
      return true;
    }

    final rawValue = company.features[feature.key];
    if (rawValue is bool) {
      return rawValue;
    }

    // Backward compatibility: old companies that do not have feature metadata
    // should keep working until the platform owner explicitly disables a module.
    return true;
  }
}

CompanyFeature? companyFeatureForLocation(String location) {
  if (location.startsWith(RouteNames.platform) ||
      location == RouteNames.login ||
      location == RouteNames.dashboard ||
      location == RouteNames.profile ||
      location == RouteNames.settings ||
      location == RouteNames.featureUnavailable) {
    return null;
  }

  if (location.startsWith(RouteNames.leads)) {
    return CompanyFeature.leads;
  }
  if (location.startsWith(RouteNames.clients)) {
    return CompanyFeature.clients;
  }
  if (location.startsWith(RouteNames.properties)) {
    return CompanyFeature.properties;
  }
  if (location.startsWith(RouteNames.tasks)) {
    return CompanyFeature.tasks;
  }
  if (location.startsWith(RouteNames.appointments)) {
    return CompanyFeature.appointments;
  }
  if (location.startsWith(RouteNames.deals)) {
    return CompanyFeature.deals;
  }
  if (location.startsWith(RouteNames.reports)) {
    return CompanyFeature.reports;
  }
  if (location.startsWith(RouteNames.auditLogs)) {
    return CompanyFeature.auditLogs;
  }
  if (location.startsWith(RouteNames.notifications)) {
    return CompanyFeature.notifications;
  }
  if (location.startsWith(RouteNames.users)) {
    return CompanyFeature.userManagement;
  }

  return null;
}
