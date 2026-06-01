import '../../../../core/routing/route_names.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';

class NotificationRouteResolution {
  const NotificationRouteResolution({
    required this.route,
    required this.usedFallback,
  });

  final String route;
  final bool usedFallback;
}

abstract final class NotificationRouteResolver {
  static NotificationRouteResolution resolve(CrmNotification notification) {
    final module = _normalizeModule(notification.module);
    final recordId = notification.recordId.trim();

    final structuredRoute = _structuredRoute(
      module: module,
      recordId: recordId,
      type: notification.type,
    );
    if (structuredRoute != null) {
      return NotificationRouteResolution(
        route: structuredRoute,
        usedFallback: false,
      );
    }

    final rawRoute = _safeStoredRoute(notification.route);
    if (rawRoute != null) {
      return NotificationRouteResolution(route: rawRoute, usedFallback: false);
    }

    return NotificationRouteResolution(
      route: _moduleFallbackRoute(module),
      usedFallback: true,
    );
  }

  static NotificationRouteResolution resolveReminder(AttentionReminder reminder) {
    final module = _normalizeModule(reminder.module);
    final recordId = reminder.recordId.trim();
    final route = switch (reminder.type) {
      AttentionReminderType.followUpDueToday =>
        RouteNames.filteredLeads(followUp: 'dueToday'),
      AttentionReminderType.followUpOverdue =>
        RouteNames.filteredLeads(followUp: 'overdue'),
      AttentionReminderType.taskDueToday => RouteNames.filteredTasks(due: 'today'),
      AttentionReminderType.taskOverdue =>
        RouteNames.filteredTasks(due: 'overdue'),
      AttentionReminderType.appointmentToday =>
        RouteNames.filteredAppointments(date: 'today'),
      AttentionReminderType.appointmentDueNow ||
      AttentionReminderType.appointmentMissed =>
        RouteNames.filteredAppointments(date: 'missed'),
      AttentionReminderType.appointmentUpcomingSoon =>
        RouteNames.filteredAppointments(date: 'upcoming'),
      AttentionReminderType.unassignedLead =>
        RouteNames.filteredLeads(queue: 'unassigned'),
    };
    if (recordId.isNotEmpty &&
        reminder.type != AttentionReminderType.appointmentDueNow &&
        reminder.type != AttentionReminderType.appointmentMissed) {
      return NotificationRouteResolution(route: route, usedFallback: false);
    }
    return NotificationRouteResolution(
      route: route.isNotEmpty ? route : _moduleFallbackRoute(module),
      usedFallback: route.isEmpty,
    );
  }

  static String? _structuredRoute({
    required String module,
    required String recordId,
    required CrmNotificationType type,
  }) {
    if (_isAppointmentAttentionType(type)) {
      return _appointmentRouteForType(type);
    }
    if (recordId.isEmpty) {
      return null;
    }
    return switch (module) {
      'leads' => RouteNames.leadDetails(recordId),
      'clients' => RouteNames.clientDetails(recordId),
      'tasks' => RouteNames.taskEdit(recordId),
      'deals' => RouteNames.dealDetails(recordId),
      'appointments' => RouteNames.appointmentEdit(recordId),
      'properties' => RouteNames.propertyDetails(recordId),
      'auditLogs' => RouteNames.auditLogs,
      'reports' => RouteNames.reports,
      'support' => RouteNames.support,
      'dataHealth' => RouteNames.dataHealth,
      'system' => RouteNames.notifications,
      _ => null,
    };
  }

  static String _appointmentRouteForType(CrmNotificationType type) {
    return switch (type) {
      CrmNotificationType.appointmentMissed ||
      CrmNotificationType.teamAppointmentMissed =>
        RouteNames.filteredAppointments(date: 'missed'),
      CrmNotificationType.appointmentDueNow ||
      CrmNotificationType.teamAppointmentDueNow =>
        RouteNames.filteredAppointments(date: 'today'),
      CrmNotificationType.appointmentDueSoon ||
      CrmNotificationType.teamAppointmentDueSoon =>
        RouteNames.filteredAppointments(date: 'upcoming'),
      _ => RouteNames.appointments,
    };
  }

  static bool _isAppointmentAttentionType(CrmNotificationType type) {
    return switch (type) {
      CrmNotificationType.appointmentDueSoon ||
      CrmNotificationType.appointmentDueNow ||
      CrmNotificationType.appointmentMissed ||
      CrmNotificationType.teamAppointmentDueSoon ||
      CrmNotificationType.teamAppointmentDueNow ||
      CrmNotificationType.teamAppointmentMissed => true,
      _ => false,
    };
  }

  static String _moduleFallbackRoute(String module) {
    return switch (module) {
      'leads' => RouteNames.leads,
      'clients' => RouteNames.clients,
      'tasks' => RouteNames.tasks,
      'deals' => RouteNames.deals,
      'appointments' => RouteNames.appointments,
      'properties' => RouteNames.properties,
      'auditLogs' => RouteNames.auditLogs,
      'reports' => RouteNames.reports,
      'support' => RouteNames.support,
      'dataHealth' => RouteNames.dataHealth,
      _ => RouteNames.notifications,
    };
  }

  static String? _safeStoredRoute(String route) {
    final cleanRoute = route.trim();
    if (cleanRoute.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(cleanRoute);
    final path = uri?.path.trim().isNotEmpty == true ? uri!.path : cleanRoute;
    final listRoute = _listRouteForDynamicPath(path);
    if (listRoute != null) {
      return listRoute;
    }
    if (!_isAllowedPath(path)) {
      return null;
    }
    if (uri != null && uri.path.trim().isNotEmpty) {
      return Uri(path: path, queryParameters: uri.queryParameters).toString();
    }
    return path;
  }

  static bool _isAllowedPath(String path) {
    return path == RouteNames.dashboard ||
        path == RouteNames.dataHealth ||
        path == RouteNames.auditLogs ||
        path == RouteNames.reports ||
        path == RouteNames.support ||
        path == RouteNames.notifications ||
        path == RouteNames.leads ||
        path == RouteNames.clients ||
        path == RouteNames.tasks ||
        path == RouteNames.deals ||
        path == RouteNames.appointments ||
        path == RouteNames.properties;
  }

  static String? _listRouteForDynamicPath(String path) {
    if (path.startsWith('/appointments/')) {
      return RouteNames.appointments;
    }
    if (path.startsWith('/leads/')) {
      return RouteNames.leads;
    }
    if (path.startsWith('/tasks/')) {
      return RouteNames.tasks;
    }
    if (path.startsWith('/deals/')) {
      return RouteNames.deals;
    }
    if (path.startsWith('/clients/')) {
      return RouteNames.clients;
    }
    if (path.startsWith('/properties/')) {
      return RouteNames.properties;
    }
    return null;
  }

  static String _normalizeModule(String module) {
    return switch (module.trim()) {
      'lead' || 'leads' => 'leads',
      'client' || 'clients' => 'clients',
      'task' || 'tasks' => 'tasks',
      'deal' || 'deals' => 'deals',
      'appointment' || 'appointments' => 'appointments',
      'property' || 'properties' => 'properties',
      'audit' || 'auditLog' || 'auditLogs' => 'auditLogs',
      'report' || 'reports' || 'export' || 'exports' => 'reports',
      'support' || 'ticket' || 'tickets' => 'support',
      'dataHealth' || 'data_health' => 'dataHealth',
      'system' => 'system',
      _ => '',
    };
  }
}
