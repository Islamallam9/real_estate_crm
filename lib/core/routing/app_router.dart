import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const _TemporaryPage(
          title: 'Login',
          description: 'Authentication screen placeholder',
        ),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const _TemporaryPage(
          title: 'Dashboard',
          description: 'CRM dashboard placeholder',
        ),
      ),
    ],
  );
}

class _TemporaryPage extends StatelessWidget {
  const _TemporaryPage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final target = title == 'Login'
                        ? RouteNames.dashboard
                        : RouteNames.login;
                    context.go(target);
                  },
                  child: Text(
                    title == 'Login' ? 'Open dashboard' : 'Back to login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
