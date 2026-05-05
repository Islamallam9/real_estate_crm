import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_state_changes_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/users/data/datasources/user_profile_remote_data_source.dart';
import 'features/users/data/repositories/user_profile_repository_impl.dart';
import 'features/users/domain/usecases/get_current_user_profile_usecase.dart';
import 'l10n/app_localizations.dart';

class RealEstateCrmApp extends StatefulWidget {
  const RealEstateCrmApp({super.key});

  @override
  State<RealEstateCrmApp> createState() => _RealEstateCrmAppState();
}

class _RealEstateCrmAppState extends State<RealEstateCrmApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authRemoteDataSource = FirebaseAuthRemoteDataSource();
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
    );
    final userProfileRemoteDataSource = FirestoreUserProfileRemoteDataSource();
    final userProfileRepository = UserProfileRepositoryImpl(
      remoteDataSource: userProfileRemoteDataSource,
    );

    _authBloc = AuthBloc(
      signInUseCase: SignInUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      authStateChangesUseCase: AuthStateChangesUseCase(authRepository),
      getCurrentUserProfileUseCase: GetCurrentUserProfileUseCase(
        userProfileRepository,
      ),
    )..add(const AuthStarted());

    _router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
