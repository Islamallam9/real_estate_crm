abstract final class RouteNames {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const leads = '/leads';
  static const properties = '/properties';
  static const leadsCreate = '/leads/create';

  static String leadDetails(String leadId) => '/leads/$leadId';
  static String leadEdit(String leadId) => '/leads/$leadId/edit';
}
