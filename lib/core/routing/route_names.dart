abstract final class RouteNames {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const leads = '/leads';
  static const properties = '/properties';
  static const clients = '/clients';
  static const tasks = '/tasks';
  static const leadsCreate = '/leads/create';
  static const propertiesCreate = '/properties/create';
  static const clientsCreate = '/clients/create';
  static const tasksCreate = '/tasks/create';

  static String leadDetails(String leadId) => '/leads/$leadId';
  static String leadEdit(String leadId) => '/leads/$leadId/edit';
  static String clientDetails(String clientId) => '/clients/$clientId';
  static String clientEdit(String clientId) => '/clients/$clientId/edit';
  static String propertyDetails(String propertyId) => '/properties/$propertyId';
  static String propertyEdit(String propertyId) => '/properties/$propertyId/edit';
  static String taskEdit(String taskId) => '/tasks/$taskId/edit';
}
