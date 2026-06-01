abstract final class RouteNames {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registerCompany = '/register-company';
  static const forceChangePassword = '/force-change-password';
  static const dashboard = '/dashboard';
  static const leads = '/leads';
  static const properties = '/properties';
  static const clients = '/clients';
  static const tasks = '/tasks';
  static const appointments = '/appointments';
  static const deals = '/deals';
  static const reports = '/reports';
  static const auditLogs = '/audit-logs';
  static const users = '/users';
  static const teams = '/teams';
  static const dataHealth = '/data-health';
  static const support = '/support';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
  static const platform = '/platform';
  static const platformMonitoring = '/platform/monitoring';
  static const platformNotifications = '/platform/notifications';
  static const platformSupport = '/platform/support';
  static const featureUnavailable = '/feature-unavailable';
  static const leadsCreate = '/leads/create';
  static const propertiesCreate = '/properties/create';
  static const clientsCreate = '/clients/create';
  static const tasksCreate = '/tasks/create';
  static const appointmentsCreate = '/appointments/create';
  static const dealsCreate = '/deals/create';

  static String filteredLeads({
    String? queue,
    String? followUp,
    String? source,
    String? assignedTo,
    String? status,
    String? priority,
  }) {
    return _withQuery(leads, {
      'queue': queue,
      'followUp': followUp,
      'source': source,
      'assignedTo': assignedTo,
      'status': status,
      'priority': priority,
    });
  }

  static String filteredProperties({String? status}) {
    return _withQuery(properties, {'status': status});
  }

  static String filteredTasks({
    String? due,
    String? status,
    String? assignedTo,
  }) {
    return _withQuery(tasks, {
      'due': due,
      'status': status,
      'assignedTo': assignedTo,
    });
  }

  static String filteredAppointments({
    String? date,
    String? selectedDate,
    String? status,
    String? assignedTo,
  }) {
    return _withQuery(appointments, {
      'date': date,
      'selectedDate': selectedDate,
      'status': status,
      'assignedTo': assignedTo,
    });
  }

  static String filteredDeals({
    String? queue,
    String? stage,
    String? assignedTo,
    String? closing,
  }) {
    return _withQuery(deals, {
      'queue': queue,
      'stage': stage,
      'assignedTo': assignedTo,
      'closing': closing,
    });
  }

  static String taskCreateFor({
    required String relatedType,
    required String relatedId,
    String? relatedTitle,
    String? relatedSubtitle,
    String? assignedTo,
  }) {
    return _withQuery(tasksCreate, {
      'relatedType': relatedType,
      'relatedId': relatedId,
      'relatedTitle': relatedTitle,
      'relatedSubtitle': relatedSubtitle,
      'assignedTo': assignedTo,
    });
  }

  static String appointmentCreateFor({
    required String relatedType,
    required String relatedId,
    String? relatedTitle,
    String? relatedSubtitle,
    String? assignedTo,
  }) {
    return _withQuery(appointmentsCreate, {
      'relatedType': relatedType,
      'relatedId': relatedId,
      'relatedTitle': relatedTitle,
      'relatedSubtitle': relatedSubtitle,
      'assignedTo': assignedTo,
    });
  }

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
  static String appointmentEdit(String appointmentId) =>
      '/appointments/$appointmentId/edit';
  static String dealDetails(String dealId) => '/deals/$dealId';
  static String dealEdit(String dealId) => '/deals/$dealId/edit';

  static String _withQuery(String path, Map<String, String?> values) {
    final query = <String, String>{};
    for (final entry in values.entries) {
      final value = entry.value?.trim() ?? '';
      if (value.isNotEmpty) {
        query[entry.key] = value;
      }
    }
    if (query.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: query).toString();
  }
}
