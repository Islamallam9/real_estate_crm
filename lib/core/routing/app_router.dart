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
import '../permissions/company_feature_gate.dart';
import '../widgets/app_error_view.dart';
import '../widgets/crm_app_shell.dart';
import 'route_names.dart';

abstract final class AppRouter {
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
            authBloc.state.userProfile?.role.name != 'admin') {
          return RouteNames.dashboard;
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
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteNames.registerCompany,
          builder: (context, state) => RegisterCompanyPage.withDependencies(
            initialCode: state.uri.queryParameters['code'],
          ),
        ),
        GoRoute(
          path: RouteNames.forceChangePassword,
          builder: (context, state) => ForceChangePasswordPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: RouteNames.leads,
          builder: (context, state) => const LeadsListPage(),
        ),
        GoRoute(
          path: RouteNames.properties,
          builder: (context, state) => const PropertiesPage(),
        ),
        GoRoute(
          path: RouteNames.clients,
          builder: (context, state) => const ClientsPage(),
        ),
        GoRoute(
          path: RouteNames.tasks,
          builder: (context, state) => const TasksPage(),
        ),
        GoRoute(
          path: RouteNames.appointments,
          builder: (context, state) => const AppointmentsPage(),
        ),
        GoRoute(
          path: RouteNames.deals,
          builder: (context, state) => const DealsPage(),
        ),
        GoRoute(
          path: RouteNames.reports,
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: RouteNames.users,
          builder: (context, state) => CompanyUsersPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.teams,
          builder: (context, state) => TeamsPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.dataHealth,
          builder: (context, state) => DataHealthPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.notifications,
          builder: (context, state) => NotificationsPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: RouteNames.support,
          builder: (context, state) => SupportPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.platform,
          builder: (context, state) => PlatformPage.withDependencies(),
        ),
        GoRoute(
          path: RouteNames.platformNotifications,
          builder: (context, state) =>
              PlatformPage.withDependencies(initialNotifications: true),
        ),
        GoRoute(
          path: RouteNames.platformSupport,
          builder: (context, state) =>
              PlatformPage.withDependencies(initialSupportInbox: true),
        ),
        GoRoute(
          path: RouteNames.featureUnavailable,
          builder: (context, state) => const _FeatureUnavailablePage(),
        ),
        GoRoute(
          path: '/platform/companies/:companyId/dashboard',
          builder: (context, state) {
            return DashboardPage(
              platformPreviewCompanyId:
                  state.pathParameters['companyId'] ?? '',
              platformPreviewCompanyName:
                  state.uri.queryParameters['name'],
            );
          },
        ),
        GoRoute(
          path: RouteNames.dealsCreate,
          builder: (context, state) => const CreateDealPage(),
        ),
        GoRoute(
          path: '/deals/:dealId/edit',
          builder: (context, state) {
            return EditDealPage(dealId: state.pathParameters['dealId'] ?? '');
          },
        ),
        GoRoute(
          path: '/deals/:dealId',
          builder: (context, state) {
            return DealDetailsPage(dealId: state.pathParameters['dealId'] ?? '');
          },
        ),
        GoRoute(
          path: RouteNames.tasksCreate,
          builder: (context, state) => const CreateTaskPage(),
        ),
        GoRoute(
          path: RouteNames.appointmentsCreate,
          builder: (context, state) => const CreateAppointmentPage(),
        ),
        GoRoute(
          path: '/appointments/:appointmentId/edit',
          builder: (context, state) {
            return EditAppointmentPage(
              appointmentId: state.pathParameters['appointmentId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/tasks/:taskId/edit',
          builder: (context, state) {
            return EditTaskPage(taskId: state.pathParameters['taskId'] ?? '');
          },
        ),
        GoRoute(
          path: RouteNames.clientsCreate,
          builder: (context, state) => const CreateClientPage(),
        ),
        GoRoute(
          path: '/clients/:clientId/edit',
          builder: (context, state) {
            return EditClientPage(
              clientId: state.pathParameters['clientId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/clients/:clientId',
          builder: (context, state) {
            return ClientDetailsPage(
              clientId: state.pathParameters['clientId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: RouteNames.propertiesCreate,
          builder: (context, state) => const CreatePropertyPage(),
        ),
        GoRoute(
          path: '/properties/:propertyId/edit',
          builder: (context, state) {
            return EditPropertyPage(
              propertyId: state.pathParameters['propertyId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/properties/:propertyId',
          builder: (context, state) {
            return PropertyDetailsPage(
              propertyId: state.pathParameters['propertyId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: RouteNames.leadsCreate,
          builder: (context, state) => const CreateLeadPage(),
        ),
        GoRoute(
          path: '/leads/:leadId/edit',
          builder: (context, state) {
            return EditLeadPage(leadId: state.pathParameters['leadId'] ?? '');
          },
        ),
        GoRoute(
          path: '/leads/:leadId',
          builder: (context, state) {
            return LeadDetailsPage(
              leadId: state.pathParameters['leadId'] ?? '',
            );
          },
        ),
      ],
    );
  }
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
