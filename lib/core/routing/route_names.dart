abstract final class RouteNames {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const leads = '/leads';
  static const leadsCreate = '/leads/create';

  static String leadDetails(String leadId) => '/leads/$leadId';
}
