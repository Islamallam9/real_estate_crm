import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/force_change_password_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/clients/presentation/pages/create_client_page.dart';
import '../../features/clients/presentation/pages/client_details_page.dart';
import '../../features/clients/presentation/pages/edit_client_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/company_registration/presentation/pages/register_company_page.dart';
import '../../features/company_users/presentation/pages/company_users_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/data_health/presentation/pages/data_health_page.dart';
import '../../features/deals/presentation/pages/create_deal_page.dart';
import '../../features/deals/presentation/pages/deal_details_page.dart';
import '../../features/deals/presentation/pages/deals_page.dart';
import '../../features/deals/presentation/pages/edit_deal_page.dart';
import '../../features/leads/presentation/pages/create_lead_page.dart';
import '../../features/leads/presentation/pages/edit_lead_page.dart';
import '../../features/leads/presentation/pages/lead_details_page.dart';
import '../../features/leads/presentation/pages/leads_list_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/create_appointment_page.dart';
import '../../features/appointments/presentation/pages/edit_appointment_page.dart';
import '../../features/properties/presentation/pages/create_property_page.dart';
import '../../features/properties/presentation/pages/edit_property_page.dart';
import '../../features/properties/presentation/pages/property_details_page.dart';
import '../../features/properties/presentation/pages/properties_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/platform/presentation/pages/platform_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/teams/presentation/pages/teams_page.dart';
import '../../features/tasks/presentation/pages/create_task_page.dart';
import '../../features/tasks/presentation/pages/edit_task_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../auth/protected_company_session.dart';
import '../constants/role_constants.dart';
import '../permissions/app_permission.dart';
import '../permissions/company_feature_gate.dart';
import '../permissions/permission_service.dart';
import '../widgets/app_error_view.dart';
import '../widgets/crm_app_shell.dart';
import 'route_names.dart';

abstract final class AppRouter {
  static Page<void> _calmPage(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: child,
        );
      },
    );
  }

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteNames.onboarding,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final status = authBloc.state.status;
        final isAuthenticated = status == AuthStatus.authenticated;
        final isCheckingAuth =
            status == AuthStatus.initial || status == AuthStatus.loading;
        final isOnboardingRoute = state.matchedLocation == RouteNames.onboarding;
        final isLoginRoute = state.matchedLocation == RouteNames.login;
        final isRegisterCompanyRoute =
            state.matchedLocation == RouteNames.registerCompany;
        final isForceChangePasswordRoute =
            state.matchedLocation == RouteNames.forceChangePassword;
        final isPlatformRoute = state.matchedLocation.startsWith(
          RouteNames.platform,
        );
        final isFeatureUnavailableRoute =
            state.matchedLocation == RouteNames.featureUnavailable;
        final isUsersRoute = state.matchedLocation == RouteNames.users;
        final isAccountUtilityRoute = state.matchedLocation == RouteNames.profile ||
            state.matchedLocation == RouteNames.settings;

        if (isCheckingAuth) {
          return null;
        }

        if (!isAuthenticated &&
            !isOnboardingRoute &&
            !isLoginRoute &&
            !isRegisterCompanyRoute) {
          return RouteNames.onboarding;
        }

        if (isAuthenticated &&
            isPlatformRoute &&
            !authBloc.state.isPlatformAdmin) {
          return RouteNames.dashboard;
        }

        if (isAuthenticated &&
            !isPlatformRoute &&
            !isFeatureUnavailableRoute &&
            !isAccountUtilityRoute &&
            authBloc.state.userProfile == null &&
            authBloc.state.isPlatformAdmin) {
          return RouteNames.platform;
        }

        final mustChangePassword = isAuthenticated &&
            !authBloc.state.isPlatformAdmin &&
            (authBloc.state.userProfile?.mustChangePassword ?? false);

        if (mustChangePassword && !isForceChangePasswordRoute) {
          return RouteNames.forceChangePassword;
        }

        if (isAuthenticated &&
            isForceChangePasswordRoute &&
            !mustChangePassword) {
          return RouteNames.dashboard;
        }

        if (isAuthenticated &&
            isUsersRoute &&
            authBloc.state.protectedCompanySession?.profile.role !=
                UserRole.admin) {
          return RouteNames.dashboard;
        }

        if (isAuthenticated &&
            !isPlatformRoute &&
            !isFeatureUnavailableRoute &&
            !isAccountUtilityRoute &&
            !isForceChangePasswordRoute) {
          final session = authBloc.state.protectedCompanySession;
          if (session == null) {
            return state.matchedLocation == RouteNames.dashboard
                ? null
                : RouteNames.dashboard;
          }

          final blockedRoute = _blockedCompanyRouteForRole(
            state.matchedLocation,
            session.profile.role,
          );
          if (blockedRoute) {
            return RouteNames.dashboard;
          }
        }

        if (isAuthenticated &&
            !isPlatformRoute &&
            !isFeatureUnavailableRoute) {
          final feature = companyFeatureForLocation(state.matchedLocation);
          if (feature != null &&
              !authBloc.state.companyMetadata.isFeatureEnabled(feature)) {
            return RouteNames.featureUnavailable;
          }
        }

        if (isAuthenticated && (isOnboardingRoute || isLoginRoute || isRegisterCompanyRoute)) {
          if (authBloc.state.isPlatformAdmin &&
              authBloc.state.userProfile == null) {
            return RouteNames.platform;
          }
          return RouteNames.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.onboarding,
          pageBuilder: (context, state) => _calmPage(state, const OnboardingPage()),
        ),
        GoRoute(
          path: RouteNames.login,
          pageBuilder: (context, state) => _calmPage(state, const LoginPage()),
        ),
        GoRoute(
          path: RouteNames.registerCompany,
          pageBuilder: (context, state) => _calmPage(
            state,
            RegisterCompanyPage.withDependencies(
              initialCode: state.uri.queryParameters['code'],
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.forceChangePassword,
          pageBuilder: (context, state) => _calmPage(
            state,
            ForceChangePasswordPage.withDependencies(),
          ),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          pageBuilder: (context, state) => _calmPage(state, const DashboardPage()),
        ),
        GoRoute(
          path: RouteNames.leads,
          pageBuilder: (context, state) => _calmPage(state, const LeadsListPage()),
        ),
        GoRoute(
          path: RouteNames.properties,
          pageBuilder: (context, state) => _calmPage(state, const PropertiesPage()),
        ),
        GoRoute(
          path: RouteNames.clients,
          pageBuilder: (context, state) => _calmPage(state, const ClientsPage()),
        ),
        GoRoute(
          path: RouteNames.tasks,
          pageBuilder: (context, state) => _calmPage(state, const TasksPage()),
        ),
        GoRoute(
          path: RouteNames.appointments,
          pageBuilder: (context, state) => _calmPage(state, const AppointmentsPage()),
        ),
        GoRoute(
          path: RouteNames.deals,
          pageBuilder: (context, state) => _calmPage(state, const DealsPage()),
        ),
        GoRoute(
          path: RouteNames.reports,
          pageBuilder: (context, state) => _calmPage(state, const ReportsPage()),
        ),
        GoRoute(
          path: RouteNames.users,
          pageBuilder: (context, state) => _calmPage(
            state,
            CompanyUsersPage.withDependencies(),
          ),
        ),
        GoRoute(
          path: RouteNames.teams,
          pageBuilder: (context, state) => _calmPage(state, TeamsPage.withDependencies()),
        ),
        GoRoute(
          path: RouteNames.dataHealth,
          pageBuilder: (context, state) => _calmPage(
            state,
            DataHealthPage.withDependencies(),
          ),
        ),
        GoRoute(
          path: RouteNames.notifications,
          pageBuilder: (context, state) => _calmPage(
            state,
            NotificationsPage.withDependencies(),
          ),
        ),
        GoRoute(
          path: RouteNames.profile,
          pageBuilder: (context, state) => _calmPage(state, const ProfilePage()),
        ),
        GoRoute(
          path: RouteNames.settings,
          pageBuilder: (context, state) => _calmPage(state, const SettingsPage()),
        ),
        GoRoute(
          path: RouteNames.support,
          pageBuilder: (context, state) => _calmPage(state, SupportPage.withDependencies()),
        ),
        GoRoute(
          path: RouteNames.platform,
          pageBuilder: (context, state) => _calmPage(
            state,
            PlatformPage.withDependencies(),
          ),
        ),
        GoRoute(
          path: RouteNames.platformNotifications,
          pageBuilder: (context, state) => _calmPage(
            state,
            PlatformPage.withDependencies(initialNotifications: true),
          ),
        ),
        GoRoute(
          path: RouteNames.platformMonitoring,
          pageBuilder: (context, state) => _calmPage(
            state,
            PlatformPage.withDependencies(initialMonitoring: true),
          ),
        ),
        GoRoute(
          path: RouteNames.platformSupport,
          pageBuilder: (context, state) => _calmPage(
            state,
            PlatformPage.withDependencies(initialSupportInbox: true),
          ),
        ),
        GoRoute(
          path: RouteNames.featureUnavailable,
          pageBuilder: (context, state) => _calmPage(
            state,
            const _FeatureUnavailablePage(),
          ),
        ),
        GoRoute(
          path: '/platform/companies/:companyId/dashboard',
          pageBuilder: (context, state) => _calmPage(
            state,
            DashboardPage(
              platformPreviewCompanyId:
                  state.pathParameters['companyId'] ?? '',
              platformPreviewCompanyName: state.uri.queryParameters['name'],
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.dealsCreate,
          pageBuilder: (context, state) => _calmPage(state, const CreateDealPage()),
        ),
        GoRoute(
          path: '/deals/:dealId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditDealPage(dealId: state.pathParameters['dealId'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/deals/:dealId',
          pageBuilder: (context, state) => _calmPage(
            state,
            DealDetailsPage(dealId: state.pathParameters['dealId'] ?? ''),
          ),
        ),
        GoRoute(
          path: RouteNames.tasksCreate,
          pageBuilder: (context, state) => _calmPage(state, const CreateTaskPage()),
        ),
        GoRoute(
          path: RouteNames.appointmentsCreate,
          pageBuilder: (context, state) => _calmPage(
            state,
            const CreateAppointmentPage(),
          ),
        ),
        GoRoute(
          path: '/appointments/:appointmentId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditAppointmentPage(
              appointmentId: state.pathParameters['appointmentId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/tasks/:taskId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditTaskPage(taskId: state.pathParameters['taskId'] ?? ''),
          ),
        ),
        GoRoute(
          path: RouteNames.clientsCreate,
          pageBuilder: (context, state) => _calmPage(state, const CreateClientPage()),
        ),
        GoRoute(
          path: '/clients/:clientId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditClientPage(
              clientId: state.pathParameters['clientId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/clients/:clientId',
          pageBuilder: (context, state) => _calmPage(
            state,
            ClientDetailsPage(
              clientId: state.pathParameters['clientId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.propertiesCreate,
          pageBuilder: (context, state) => _calmPage(
            state,
            const CreatePropertyPage(),
          ),
        ),
        GoRoute(
          path: '/properties/:propertyId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditPropertyPage(
              propertyId: state.pathParameters['propertyId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/properties/:propertyId',
          pageBuilder: (context, state) => _calmPage(
            state,
            PropertyDetailsPage(
              propertyId: state.pathParameters['propertyId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.leadsCreate,
          pageBuilder: (context, state) => _calmPage(state, const CreateLeadPage()),
        ),
        GoRoute(
          path: '/leads/:leadId/edit',
          pageBuilder: (context, state) => _calmPage(
            state,
            EditLeadPage(leadId: state.pathParameters['leadId'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/leads/:leadId',
          pageBuilder: (context, state) => _calmPage(
            state,
            LeadDetailsPage(
              leadId: state.pathParameters['leadId'] ?? '',
            ),
          ),
        ),
      ],
    );
  }
}

bool _blockedCompanyRouteForRole(String location, UserRole role) {
  if (location == RouteNames.users || location == RouteNames.dataHealth) {
    return role != UserRole.admin;
  }
  if (location == RouteNames.teams) {
    return role != UserRole.admin && role != UserRole.manager;
  }

  final permission = _permissionForCompanyLocation(location);
  return permission != null && !PermissionService.can(role, permission);
}

AppPermission? _permissionForCompanyLocation(String location) {
  if (location == RouteNames.dashboard) {
    return AppPermission.viewDashboard;
  }
  if (location == RouteNames.reports) {
    return AppPermission.viewReports;
  }
  if (location == RouteNames.leadsCreate) {
    return AppPermission.createLead;
  }
  if (location.startsWith('${RouteNames.leads}/') && location.endsWith('/edit')) {
    return AppPermission.editLead;
  }
  if (location == RouteNames.leads || location.startsWith('${RouteNames.leads}/')) {
    return AppPermission.viewLeads;
  }
  if (location == RouteNames.clientsCreate) {
    return AppPermission.createClient;
  }
  if (location.startsWith('${RouteNames.clients}/') && location.endsWith('/edit')) {
    return AppPermission.editClient;
  }
  if (location == RouteNames.clients ||
      location.startsWith('${RouteNames.clients}/')) {
    return AppPermission.viewClients;
  }
  if (location == RouteNames.tasksCreate) {
    return AppPermission.createTask;
  }
  if (location.startsWith('${RouteNames.tasks}/') && location.endsWith('/edit')) {
    return AppPermission.viewTasks;
  }
  if (location == RouteNames.tasks || location.startsWith('${RouteNames.tasks}/')) {
    return AppPermission.viewTasks;
  }
  if (location == RouteNames.appointmentsCreate) {
    return AppPermission.createAppointment;
  }
  if (location.startsWith('${RouteNames.appointments}/') &&
      location.endsWith('/edit')) {
    return AppPermission.viewAppointments;
  }
  if (location == RouteNames.appointments ||
      location.startsWith('${RouteNames.appointments}/')) {
    return AppPermission.viewAppointments;
  }
  if (location == RouteNames.dealsCreate) {
    return AppPermission.createDeal;
  }
  if (location.startsWith('${RouteNames.deals}/') && location.endsWith('/edit')) {
    return AppPermission.editDeal;
  }
  if (location == RouteNames.deals || location.startsWith('${RouteNames.deals}/')) {
    return AppPermission.viewDeals;
  }
  if (location == RouteNames.propertiesCreate) {
    return AppPermission.createProperty;
  }
  if (location.startsWith('${RouteNames.properties}/') &&
      location.endsWith('/edit')) {
    return AppPermission.editProperty;
  }
  if (location == RouteNames.properties ||
      location.startsWith('${RouteNames.properties}/')) {
    return AppPermission.viewProperties;
  }
  return null;
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}


class _FeatureUnavailablePage extends StatelessWidget {
  const _FeatureUnavailablePage();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.dashboard,
      title: l.featureUnavailable,
      child: AppErrorView(
        title: l.featureUnavailable,
        message: l.featureNotEnabledForWorkspace,
        onRetry: () => context.go(RouteNames.dashboard),
      ),
    );
  }
}
