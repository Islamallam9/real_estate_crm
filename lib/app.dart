import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/role_constants.dart';
import 'core/connectivity/connectivity_feedback_scope.dart';
import 'core/localization/locale_cubit.dart';
import 'core/observability/app_error_reporter.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/app_feedback.dart';
import 'core/widgets/crm_app_shell.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/app_update/presentation/widgets/android_update_gate.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_state_changes_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/record_login_activity_usecase.dart';
import 'features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/device_lifecycle/presentation/widgets/device_lifecycle_scope.dart';
import 'features/notifications/presentation/widgets/notification_push_token_scope.dart';
import 'features/platform_observability/data/datasources/platform_observability_remote_data_source.dart';
import 'features/platform_observability/data/repositories/platform_observability_repository_impl.dart';
import 'features/platform_observability/domain/usecases/report_client_error_usecase.dart';
import 'features/users/data/datasources/user_profile_remote_data_source.dart';
import 'features/users/data/datasources/company_resolver_remote_data_source.dart';
import 'features/users/data/repositories/user_profile_repository_impl.dart';
import 'features/users/data/repositories/company_resolver_repository_impl.dart';
import 'features/users/domain/usecases/get_current_user_profile_usecase.dart';
import 'features/users/domain/usecases/resolve_auth_company_usecase.dart';
import 'l10n/app_localizations.dart';

class RealEstateCrmApp extends StatefulWidget {
  const RealEstateCrmApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<RealEstateCrmApp> createState() => _RealEstateCrmAppState();
}

class _RealEstateCrmAppState extends State<RealEstateCrmApp> {
  late final AuthBloc _authBloc;
  late final LocaleCubit _localeCubit;
  late final ThemeCubit _themeCubit;
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
    final companyResolverRemoteDataSource =
        FirestoreCompanyResolverRemoteDataSource();
    final companyResolverRepository = CompanyResolverRepositoryImpl(
      remoteDataSource: companyResolverRemoteDataSource,
    );

    _authBloc = AuthBloc(
      signInUseCase: SignInUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      sendPasswordResetEmailUseCase: SendPasswordResetEmailUseCase(
        authRepository,
      ),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      authStateChangesUseCase: AuthStateChangesUseCase(authRepository),
      getCurrentUserProfileUseCase: GetCurrentUserProfileUseCase(
        userProfileRepository,
      ),
      resolveAuthCompanyUseCase: ResolveAuthCompanyUseCase(
        companyResolverRepository,
      ),
      recordLoginActivityUseCase: RecordLoginActivityUseCase(authRepository),
    )..add(const AuthStarted());

    _router = AppRouter.createRouter(_authBloc);
    final observabilityRemoteDataSource =
        FirebasePlatformObservabilityRemoteDataSource();
    final observabilityRepository = PlatformObservabilityRepositoryImpl(
      remoteDataSource: observabilityRemoteDataSource,
    );
    MasarObservabilityReporter.instance.configure(
      reportClientErrorUseCase: ReportClientErrorUseCase(
        observabilityRepository,
      ),
      contextProvider: _observabilityContext,
    );
    _localeCubit = LocaleCubit(initialLocale: widget.initialLocale)
      ..loadSavedLocale();
    _themeCubit = ThemeCubit()..loadSavedThemeMode();
  }

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    _localeCubit.close();
    _themeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _localeCubit),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return DeviceLifecycleScope(
                child: NotificationPushTokenScope(
                  child: MaterialApp.router(
                  scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
                locale: locale,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.websiteTitle,
                debugShowCheckedModeBanner: false,
                theme: _localizedTheme(AppTheme.light, locale),
                darkTheme: _localizedTheme(AppTheme.dark, locale),
                themeMode: themeMode,
                routerConfig: _router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    return BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (previous, current) =>
                          previous.status != current.status ||
                          previous.user != current.user ||
                          previous.userProfile != current.userProfile ||
                          previous.companyMetadata != current.companyMetadata ||
                          previous.isPlatformAdmin != current.isPlatformAdmin,
                      builder: (context, authState) {
                        return CrmNotificationsOverlayScope(
                          authState: authState,
                          child: ConnectivityFeedbackScope(
                            child: AndroidUpdateGate(
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  MasarObservabilityContext _observabilityContext() {
    final state = _authBloc.state;
    final user = state.user;
    final profile = state.userProfile;
    final company = state.companyMetadata;
    var route = '';
    try {
      route = _router.routeInformationProvider.value.uri.toString();
    } catch (_) {
      route = '';
    }
    final companyName = (company?.displayName ?? '').trim().isNotEmpty
        ? company!.displayName
        : (company?.name ?? '');
    return MasarObservabilityContext(
      companyId: profile?.companyId ?? user?.companyId ?? company?.id ?? '',
      companyName: companyName,
      userId: profile?.uid ?? user?.uid ?? '',
      userEmail: profile?.email ?? user?.email ?? '',
      userRole: profile == null
          ? (state.isPlatformAdmin ? 'platformAdmin' : '')
          : RoleConstants.toValue(profile.role),
      route: route,
    );
  }
}

ThemeData _localizedTheme(ThemeData theme, Locale? locale) {
  final isArabic = locale?.languageCode == 'ar';

  final fontFamily = isArabic ? 'IBM Plex Sans Arabic' : 'Plus Jakarta Sans';
  final fallback = isArabic
      ? <String>['Tahoma', 'Arial', 'sans-serif']
      : <String>['Roboto', 'Segoe UI', 'Arial', 'sans-serif'];

  TextTheme localizeTextTheme(TextTheme textTheme) {
    return textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
    );
  }

  TextStyle? localizeTextStyle(TextStyle? style) {
    if (style == null) return null;

    return style.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
    );
  }

  WidgetStateProperty<TextStyle?>? localizeStateTextStyle(
    WidgetStateProperty<TextStyle?>? property,
  ) {
    final style = property?.resolve(<WidgetState>{});
    if (style == null) return property;
    return WidgetStatePropertyAll<TextStyle?>(localizeTextStyle(style));
  }

  return theme.copyWith(
    textTheme: localizeTextTheme(theme.textTheme),
    primaryTextTheme: localizeTextTheme(theme.primaryTextTheme),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: localizeTextStyle(theme.appBarTheme.titleTextStyle),
    ),
    snackBarTheme: theme.snackBarTheme.copyWith(
      contentTextStyle: localizeTextStyle(
        theme.snackBarTheme.contentTextStyle,
      ),
    ),
    popupMenuTheme: theme.popupMenuTheme.copyWith(
      textStyle: localizeTextStyle(theme.popupMenuTheme.textStyle),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      labelStyle: localizeTextStyle(theme.inputDecorationTheme.labelStyle),
      hintStyle: localizeTextStyle(theme.inputDecorationTheme.hintStyle),
      errorStyle: localizeTextStyle(theme.inputDecorationTheme.errorStyle),
      helperStyle: localizeTextStyle(theme.inputDecorationTheme.helperStyle),
      prefixStyle: localizeTextStyle(theme.inputDecorationTheme.prefixStyle),
      suffixStyle: localizeTextStyle(theme.inputDecorationTheme.suffixStyle),
      counterStyle: localizeTextStyle(theme.inputDecorationTheme.counterStyle),
      floatingLabelStyle: localizeTextStyle(
        theme.inputDecorationTheme.floatingLabelStyle,
      ),
    ),
    navigationBarTheme: theme.navigationBarTheme.copyWith(
      labelTextStyle: localizeStateTextStyle(
        theme.navigationBarTheme.labelTextStyle,
      ),
    ),
    dataTableTheme: theme.dataTableTheme.copyWith(
      headingTextStyle: localizeTextStyle(
        theme.dataTableTheme.headingTextStyle,
      ),
      dataTextStyle: localizeTextStyle(theme.dataTableTheme.dataTextStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        textStyle: localizeStateTextStyle(
          theme.filledButtonTheme.style?.textStyle,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        textStyle: localizeStateTextStyle(
          theme.outlinedButtonTheme.style?.textStyle,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: theme.textButtonTheme.style?.copyWith(
        textStyle: localizeStateTextStyle(
          theme.textButtonTheme.style?.textStyle,
        ),
      ),
    ),
    tabBarTheme: theme.tabBarTheme.copyWith(
      labelStyle: localizeTextStyle(theme.tabBarTheme.labelStyle),
      unselectedLabelStyle: localizeTextStyle(
        theme.tabBarTheme.unselectedLabelStyle,
      ),
    ),
  );
}
