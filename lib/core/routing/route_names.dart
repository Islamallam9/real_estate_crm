abstract final class RouteNames {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const leads = '/leads';
  static const properties = '/properties';
  static const clients = '/clients';
  static const tasks = '/tasks';
  static const deals = '/deals';
  static const reports = '/reports';
  static const teams = '/teams';
  static const dataHealth = '/data-health';
  static const profile = '/profile';
  static const settings = '/settings';
  static const platform = '/platform';
  static const featureUnavailable = '/feature-unavailable';
  static const leadsCreate = '/leads/create';
  static const propertiesCreate = '/properties/create';
  static const clientsCreate = '/clients/create';
  static const tasksCreate = '/tasks/create';
  static const dealsCreate = '/deals/create';

  static String platformCompanyDashboard(String companyId) {
    return '/platform/companies/$companyId/dashboard';
  }

  static String leadDetails(String leadId) => '/leads/$leadId';
  static String leadEdit(String leadId) => '/leads/$leadId/edit';
  static String clientDetails(String clientId) => '/clients/$clientId';
  static String clientEdit(String clientId) => '/clients/$clientId/edit';
  static String propertyDetails(String propertyId) => '/properties/$propertyId';
  static String propertyEdit(String propertyId) => '/properties/$propertyId/edit';
  static String taskEdit(String taskId) => '/tasks/$taskId/edit';
  static String dealDetails(String dealId) => '/deals/$dealId';
  static String dealEdit(String dealId) => '/deals/$dealId/edit';
}
