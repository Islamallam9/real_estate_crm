import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import 'route_names.dart';

abstract final class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteNames.login,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final status = authBloc.state.status;
        final isAuthenticated = status == AuthStatus.authenticated;
        final isCheckingAuth =
            status == AuthStatus.initial || status == AuthStatus.loading;
        final isLoginRoute = state.matchedLocation == RouteNames.login;

        if (isCheckingAuth) {
          return null;
        }

        if (!isAuthenticated && !isLoginRoute) {
          return RouteNames.login;
        }

        if (isAuthenticated && isLoginRoute) {
          return RouteNames.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
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
