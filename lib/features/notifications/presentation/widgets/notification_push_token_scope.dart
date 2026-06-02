import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/permissions/company_feature_gate.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/notification_push_token_remote_data_source.dart';
import '../../data/repositories/notification_push_token_repository_impl.dart';
import '../cubit/notification_push_token_cubit.dart';

class NotificationPushTokenScope extends StatelessWidget {
  const NotificationPushTokenScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = NotificationPushTokenRepositoryImpl(
      remoteDataSource: FirebaseNotificationPushTokenRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => NotificationPushTokenCubit(repository: repository),
      child: _NotificationPushTokenBridge(child: child),
    );
  }
}

class _NotificationPushTokenBridge extends StatefulWidget {
  const _NotificationPushTokenBridge({required this.child});

  final Widget child;

  @override
  State<_NotificationPushTokenBridge> createState() =>
      _NotificationPushTokenBridgeState();
}

class _NotificationPushTokenBridgeState
    extends State<_NotificationPushTokenBridge> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _sync(context, context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    _sync(context, context.read<AuthBloc>().state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              _targetKey(previous, context.read<LocaleCubit>().state) !=
              _targetKey(current, context.read<LocaleCubit>().state),
          listener: (context, state) => _sync(context, state),
        ),
        BlocListener<LocaleCubit, Locale?>(
          listener: (context, _) => _sync(
            context,
            context.read<AuthBloc>().state,
          ),
        ),
      ],
      child: widget.child,
    );
  }

  void _sync(BuildContext context, AuthState authState) {
    final cubit = context.read<NotificationPushTokenCubit>();
    final locale = _localeCode(context.read<LocaleCubit>().state);
    final session = authState.protectedCompanySession;
    if (session != null &&
        (authState.companyMetadata?.isFeatureEnabled(
              CompanyFeature.notifications,
            ) ??
            false)) {
      cubit.syncCompany(
        companyId: session.companyId,
        uid: session.uid,
        role: RoleConstants.toValue(session.profile.role),
        locale: locale,
      );
      return;
    }

    final user = authState.user;
    if (authState.status == AuthStatus.authenticated &&
        authState.isPlatformAdmin &&
        user != null) {
      cubit.syncPlatformOwner(uid: user.uid, locale: locale);
      return;
    }

    cubit.clear();
  }

  String _targetKey(AuthState state, Locale? locale) {
    final localeCode = _localeCode(locale);
    final session = state.protectedCompanySession;
    if (session != null &&
        (state.companyMetadata?.isFeatureEnabled(
              CompanyFeature.notifications,
            ) ??
            false)) {
      return 'company:${session.companyId}:${session.uid}:${session.profile.role.name}:$localeCode';
    }
    final user = state.user;
    if (state.status == AuthStatus.authenticated &&
        state.isPlatformAdmin &&
        user != null) {
      return 'platformOwner:${user.uid}:$localeCode';
    }
    return 'none';
  }

  String _localeCode(Locale? locale) {
    final code = locale?.languageCode.trim().toLowerCase();
    if (code == 'ar') {
      return 'ar';
    }
    return 'en';
  }
}
