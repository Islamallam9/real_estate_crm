import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/device_lifecycle_remote_data_source.dart';
import '../../data/repositories/device_lifecycle_repository_impl.dart';
import '../cubit/device_lifecycle_cubit.dart';

class DeviceLifecycleScope extends StatelessWidget {
  const DeviceLifecycleScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = DeviceLifecycleRepositoryImpl(
      remoteDataSource: FirebaseDeviceLifecycleRemoteDataSource(),
    );
    return BlocProvider(
      create: (_) => DeviceLifecycleCubit(repository: repository),
      child: _DeviceLifecycleBridge(child: child),
    );
  }
}

class _DeviceLifecycleBridge extends StatefulWidget {
  const _DeviceLifecycleBridge({required this.child});

  final Widget child;

  @override
  State<_DeviceLifecycleBridge> createState() => _DeviceLifecycleBridgeState();
}

class _DeviceLifecycleBridgeState extends State<_DeviceLifecycleBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _register(context, context.read<AuthBloc>().state, 'appStart');
      }
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
    final authState = context.read<AuthBloc>().state;
    final session = authState.protectedCompanySession;
    if (session == null) {
      return;
    }
    context.read<DeviceLifecycleCubit>().heartbeat(
          companyId: session.companyId,
          uid: session.uid,
          role: RoleConstants.toValue(session.profile.role),
          locale: _localeCode(context.read<LocaleCubit>().state),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              _targetKey(previous, context.read<LocaleCubit>().state) !=
              _targetKey(current, context.read<LocaleCubit>().state),
          listener: (context, state) => _register(context, state, 'login'),
        ),
        BlocListener<LocaleCubit, Locale?>(
          listener: (context, _) => _register(
            context,
            context.read<AuthBloc>().state,
            'appStart',
          ),
        ),
      ],
      child: widget.child,
    );
  }

  void _register(BuildContext context, AuthState authState, String source) {
    final session = authState.protectedCompanySession;
    if (session == null) {
      context.read<DeviceLifecycleCubit>().clear();
      return;
    }
    context.read<DeviceLifecycleCubit>().registerCompanySession(
          companyId: session.companyId,
          uid: session.uid,
          role: RoleConstants.toValue(session.profile.role),
          locale: _localeCode(context.read<LocaleCubit>().state),
          source: source,
        );
  }

  String _targetKey(AuthState state, Locale? locale) {
    final session = state.protectedCompanySession;
    if (session == null) {
      return 'none';
    }
    return '${session.companyId}:${session.uid}:${session.profile.role.name}:${_localeCode(locale)}';
  }

  String _localeCode(Locale? locale) {
    return locale?.languageCode.trim().toLowerCase() == 'ar' ? 'ar' : 'en';
  }
}
