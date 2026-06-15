import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/global_search/data/datasources/global_search_remote_data_source.dart';
import '../../features/global_search/data/repositories/global_search_repository_impl.dart';
import '../../features/global_search/domain/entities/global_search_result.dart';
import '../../features/global_search/domain/usecases/search_global_data_usecase.dart';
import '../../features/global_search/presentation/cubit/global_search_cubit.dart';
import '../../features/global_search/presentation/cubit/global_search_state.dart';
import '../../features/notifications/domain/entities/attention_reminder.dart';
import '../../features/notifications/domain/entities/crm_notification.dart';
import '../../features/notifications/presentation/cubit/notification_push_token_cubit.dart';
import '../../features/notifications/presentation/cubit/notification_push_token_state.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_state.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';
import '../../features/notifications/presentation/widgets/notifications_scope.dart';
import '../../features/notifications/presentation/widgets/notification_text.dart';
import '../../features/notifications/presentation/widgets/notification_push_status_card.dart';
import '../../features/notifications/presentation/routing/notification_route_resolver.dart';
import '../../features/notifications/presentation/routing/web_foreground_notification_notifier.dart';
import '../../features/users/domain/entities/company_metadata.dart';
import '../auth/protected_company_session.dart';
import '../constants/role_constants.dart';
import '../localization/locale_cubit.dart';
import '../permissions/app_permission.dart';
import '../permissions/permission_service.dart';
import '../platform/browser_title_updater.dart';
import '../permissions/company_feature_gate.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../routing/route_names.dart';
import 'app_feedback.dart';
import 'masar_brand.dart';
import 'masar_page_entrance.dart';
import 'masar_refresh_indicator.dart';
import 'masar_user_avatar.dart';
import 'masar_loading_view.dart';
import 'responsive_layout.dart';

enum CrmNavigationItem {
  dashboard,
  leads,
  properties,
  clients,
  tasks,
  appointments,
  deals,
  reports,
  auditLogs,
  users,
  teams,
  dataHealth,
  support,
  more,
}

class CrmAppShell extends StatelessWidget {
  const CrmAppShell({
    super.key,
    required this.selectedItem,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  static const _items = <_CrmShellItem>[
    _CrmShellItem(
      item: CrmNavigationItem.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.leads,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.properties,
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.clients,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.tasks,
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.appointments,
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.deals,
      icon: Icons.handshake_outlined,
      selectedIcon: Icons.handshake,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.reports,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.auditLogs,
      icon: Icons.manage_search_outlined,
      selectedIcon: Icons.manage_search,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.users,
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.teams,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.dataHealth,
      icon: Icons.health_and_safety_outlined,
      selectedIcon: Icons.health_and_safety,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.support,
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
    ),
  ];

  static const _mobileItems = <_CrmShellItem>[
    _CrmShellItem(
      item: CrmNavigationItem.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.leads,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.properties,
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.clients,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.more,
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final companyMetadata = context.select(
      (AuthBloc bloc) => bloc.state.companyMetadata,
    );
    final authState = context.watch<AuthBloc>().state;
    final desktopItems = _visibleItemsForRole(
      _items,
      authState.protectedCompanySession?.profile.role,
    );
    final mobileItems = _mobileItems;
    final effectiveOnItemSelected =
        onItemSelected ?? (item) => _goToItem(context, item);

    return _AuthLogoutListener(
      child: ResponsiveLayout(
        mobile: _MobileShell(
          selectedItem: selectedItem,
          title: title,
          items: mobileItems,
          companyMetadata: companyMetadata,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
        tablet: _DesktopShell(
          selectedItem: selectedItem,
          title: title,
          items: desktopItems,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
        desktop: _DesktopShell(
          selectedItem: selectedItem,
          title: title,
          items: desktopItems,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
      ),
    );
  }
}

class _ShellRefreshWrapper extends StatefulWidget {
  const _ShellRefreshWrapper({required this.child});

  final Widget child;

  @override
  State<_ShellRefreshWrapper> createState() => _ShellRefreshWrapperState();
}

class _ShellRefreshWrapperState extends State<_ShellRefreshWrapper> {
  int _refreshSeed = 0;

  Future<void> _handleRefresh() async {
    final authState = context.read<AuthBloc>().state;
    final profile = authState.userProfile;
    if (profile != null && authState.user?.uid == profile.uid) {
      try {
        context.read<NotificationsCubit>().refreshShell(
              companyId: profile.companyId,
              currentUserId: profile.uid,
              role: profile.role,
              managerTeamId: profile.teamId,
            );
      } catch (_) {
        // Some public/platform pages do not provide company notification scope.
      }
    }
    if (mounted) {
      setState(() => _refreshSeed++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasarRefreshIndicator(
      onRefresh: _handleRefresh,
      child: MasarPageEntrance(
        key: ValueKey('shell-refresh-$_refreshSeed'),
        child: widget.child,
      ),
    );
  }
}

class CrmNotificationsOverlayScope extends StatelessWidget {
  const CrmNotificationsOverlayScope({
    super.key,
    required this.authState,
    required this.child,
  });

  final AuthState authState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = authState.protectedCompanySession;
    if (session == null ||
        !authState.companyMetadata.isFeatureEnabled(CompanyFeature.notifications)) {
      return child;
    }
    final profile = session.profile;

    return NotificationsScope(
      key: ValueKey(
        session.scopeKey('notifications-scope'),
      ),
      child: _CrmNotificationsStarter(
        companyId: session.companyId,
        currentUserId: session.uid,
        role: profile.role,
        managerTeamId: profile.teamId,
        child: child,
      ),
    );
  }
}

class _CrmNotificationsStarter extends StatefulWidget {
  const _CrmNotificationsStarter({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    required this.managerTeamId,
    required this.child,
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String managerTeamId;
  final Widget child;

  @override
  State<_CrmNotificationsStarter> createState() =>
      _CrmNotificationsStarterState();
}


class _NotificationPermissionBanner extends StatelessWidget {
  const _NotificationPermissionBanner();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return PositionedDirectional(
      top: isMobile ? AppSpacing.sm : AppSpacing.lg,
      start: isMobile ? AppSpacing.sm : null,
      end: isMobile ? AppSpacing.sm : AppSpacing.xl,
      child: const SafeArea(
        child: NotificationPushStatusCard(
          mode: NotificationPushStatusCardMode.banner,
        ),
      ),
    );
  }
}


class _PushNotificationOpenRouter extends StatefulWidget {
  const _PushNotificationOpenRouter({required this.child});

  final Widget child;

  @override
  State<_PushNotificationOpenRouter> createState() =>
      _PushNotificationOpenRouterState();
}

class _PushNotificationOpenRouterState
    extends State<_PushNotificationOpenRouter> {
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<Object?>? _webClickSubscription;
  final Set<String> _handledMessages = <String>{};
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    if (kIsWeb) {
      _foregroundSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _webClickSubscription = listenForMasarWebNotificationClicks(_queueRoute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleOpenedMessage(initial);
      }
      _flushPendingRoute();
    });
  }

  @override
  void dispose() {
    _openedSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _webClickSubscription?.cancel();
    super.dispose();
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final signature = message.messageId ??
        message.sentTime?.toIso8601String() ??
        message.data.toString();
    if (!_handledMessages.add(signature)) {
      return;
    }
    final resolution = NotificationRouteResolver.resolvePushData(message.data);
    _queueRoute(resolution.route);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!kIsWeb) {
      return;
    }
    final resolution = NotificationRouteResolver.resolvePushData(message.data);
    final notification = message.notification;
    final title = notification?.title ??
        (message.data['title']?.toString() ?? 'Masar CRM');
    final body = notification?.body ??
        (message.data['body']?.toString() ??
            'Open Masar CRM to review the latest update.');
    final tag = message.data['dedupeKey']?.toString() ??
        message.data['notificationId']?.toString() ??
        message.messageId ??
        resolution.route;
    await showMasarWebForegroundNotification(
      title: title,
      body: body,
      route: resolution.route,
      tag: tag,
    );
  }

  void _queueRoute(String route) {
    final cleanRoute = _safePushRoute(route);
    _pendingRoute = cleanRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingRoute());
  }

  String _safePushRoute(String route) {
    final trimmed = route.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('javascript:')) {
      return RouteNames.notifications;
    }
    if (trimmed.startsWith('/#')) {
      final hashIndex = trimmed.indexOf('#');
      final hashRoute = hashIndex >= 0 ? trimmed.substring(hashIndex + 1).trim() : '';
      return hashRoute.startsWith('/') ? hashRoute : RouteNames.notifications;
    }
    if (trimmed.startsWith('#/')) {
      return trimmed.substring(1);
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  void _flushPendingRoute() {
    if (!mounted) {
      return;
    }
    final route = _pendingRoute;
    if (route == null || route.trim().isEmpty) {
      return;
    }
    _pendingRoute = null;
    try {
      context.go(route);
    } catch (_) {
      context.go(RouteNames.notifications);
      return;
    }
    // Some push taps arrive while the shell is rebuilding after resume. A
    // short second pass keeps routing reliable without duplicating navigation.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      try {
        if (GoRouterState.of(context).uri.toString() != route) {
          context.go(route);
        }
      } catch (_) {
        context.go(RouteNames.notifications);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingRoute());
    return widget.child;
  }
}

class _CrmNotificationsStarterState extends State<_CrmNotificationsStarter> {
  @override
  void initState() {
    super.initState();
    _watchNotifications();
  }

  @override
  void didUpdateWidget(covariant _CrmNotificationsStarter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.role != widget.role ||
        oldWidget.managerTeamId != widget.managerTeamId) {
      _watchNotifications();
    }
  }

  void _watchNotifications() {
    context.read<NotificationsCubit>().watchShell(
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return _PushNotificationOpenRouter(
      child: Stack(
        children: [
          widget.child,
          const _BrowserNotificationTitleSync(),
          const _NotificationPermissionBanner(),
          // Toast for brand-new notifications only.
          // This is separate from the smart guidance overlay, which rotates
          // existing attention reminders and can appear on any CRM page.
          _NotificationFloatingToast(
            companyId: widget.companyId,
          ),
          _SmartGuidanceFloatingOverlay(
            companyId: widget.companyId,
            currentUserId: widget.currentUserId,
            role: widget.role,
            managerTeamId: widget.managerTeamId,
          ),
        ],
      ),
    );
  }
}


class _BrowserNotificationTitleSync extends StatefulWidget {
  const _BrowserNotificationTitleSync();

  @override
  State<_BrowserNotificationTitleSync> createState() =>
      _BrowserNotificationTitleSyncState();
}

class _BrowserNotificationTitleSyncState
    extends State<_BrowserNotificationTitleSync> {
  String _baseTitle = 'Masar | CRM';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _baseTitle = AppLocalizations.of(context)?.websiteTitle ?? _baseTitle;
    _updateTitle(context.read<NotificationsCubit>().state.effectiveBadgeCount);
  }

  @override
  void dispose() {
    setBrowserTitle(_baseTitle);
    super.dispose();
  }

  void _updateTitle(int unreadCount) {
    if (unreadCount <= 0) {
      setBrowserTitle(_baseTitle);
      return;
    }
    final badge = unreadCount > 99 ? '99+' : unreadCount.toString();
    setBrowserTitle('($badge) $_baseTitle');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.effectiveBadgeCount != current.effectiveBadgeCount,
      listener: (context, state) => _updateTitle(state.effectiveBadgeCount),
      child: const SizedBox.shrink(),
    );
  }
}

class _NotificationFloatingToast extends StatefulWidget {
  const _NotificationFloatingToast({required this.companyId});

  final String companyId;

  @override
  State<_NotificationFloatingToast> createState() =>
      _NotificationFloatingToastState();
}

class _NotificationFloatingToastState
    extends State<_NotificationFloatingToast> {
  final Set<String> _knownNotificationIds = <String>{};
  CrmNotification? _visibleNotification;
  Timer? _hideTimer;
  bool _primed = false;
  late final DateTime _createdAt = DateTime.now();

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handleNotifications(NotificationsState state) {
    final currentIds = state.notifications.map((item) => item.id).toSet();
    if (!_primed) {
      _knownNotificationIds
        ..clear()
        ..addAll(currentIds);
      _primed = true;
      final recentUnread = state.notifications.where(_shouldShowOnFirstPrime).toList();
      if (recentUnread.isNotEmpty) {
        recentUnread.sort(_compareToastNotificationRecency);
        _show(recentUnread.first);
      }
      return;
    }

    final newNotifications = state.notifications
        .where((item) => !_knownNotificationIds.contains(item.id))
        .where(_shouldShowAfterPrime)
        .toList();
    _knownNotificationIds
      ..clear()
      ..addAll(currentIds);

    if (newNotifications.isEmpty) {
      return;
    }

    newNotifications.sort(_compareToastNotificationRecency);
    _show(newNotifications.first);
  }

  bool _shouldShowOnFirstPrime(CrmNotification item) {
    return _isFreshUnreadToastCandidate(
      item,
      lowerBound: _createdAt.subtract(const Duration(seconds: 12)),
    );
  }

  bool _shouldShowAfterPrime(CrmNotification item) {
    return _isFreshUnreadToastCandidate(
      item,
      lowerBound: _createdAt,
    );
  }

  bool _isFreshUnreadToastCandidate(
    CrmNotification item, {
    required DateTime lowerBound,
  }) {
    if (item.isRead || item.isDismissed) {
      return false;
    }
    final createdAt = item.createdAt;
    if (createdAt == null) {
      return false;
    }
    final now = DateTime.now();
    if (createdAt.isBefore(lowerBound)) {
      return false;
    }
    // Guard against legacy/backfilled documents and delayed query pages showing
    // as brand-new overlay toasts. The full notification center can still show
    // old records; the floating toast is only for fresh events.
    if (createdAt.isBefore(now.subtract(const Duration(minutes: 2)))) {
      return false;
    }
    if (createdAt.isAfter(now.add(const Duration(minutes: 1)))) {
      return false;
    }
    return true;
  }

  int _compareToastNotificationRecency(
    CrmNotification a,
    CrmNotification b,
  ) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  void _show(CrmNotification notification) {
    _hideTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _visibleNotification = notification);
    _showForegroundBrowserNotification(notification);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _visibleNotification = null);
      }
    });
  }

  void _showForegroundBrowserNotification(CrmNotification notification) {
    if (!kIsWeb ||
        notification.deliveryMode != CrmNotificationDeliveryMode.pushEligible) {
      return;
    }
    final pushState = context.read<NotificationPushTokenCubit>().state;
    if (!pushState.isRegistered) {
      return;
    }
    final l = AppLocalizations.of(context);
    if (l == null) {
      return;
    }
    final route = notification.route.trim().isEmpty
        ? RouteNames.notifications
        : notification.route.trim();
    final tag = notification.dedupeKey.trim().isEmpty
        ? notification.id
        : notification.dedupeKey.trim();
    unawaited(
      showMasarWebForegroundNotification(
        title: notificationTitle(l, notification),
        body: notificationBody(l, notification),
        route: route,
        tag: tag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return PositionedDirectional(
      top: 0,
      end: isMobile ? AppSpacing.sm : AppSpacing.xl,
      start: isMobile ? AppSpacing.sm : null,
      child: SafeArea(
        minimum: EdgeInsets.only(
          top: isMobile ? AppSpacing.sm : AppSpacing.xl,
        ),
        child: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: (previous, current) =>
            previous.notifications != current.notifications,
        listener: (context, state) => _handleNotifications(state),
        child: IgnorePointer(
          ignoring: _visibleNotification == null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final direction = Directionality.of(context) == TextDirection.rtl
                  ? -1.0
                  : 1.0;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.16 * direction, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _visibleNotification == null
                ? const SizedBox.shrink(key: ValueKey('notification-toast-empty'))
                : _NotificationToastCard(
                    key: ValueKey(_visibleNotification!.id),
                    companyId: widget.companyId,
                    notification: _visibleNotification!,
                    onClose: () {
                      _hideTimer?.cancel();
                      setState(() => _visibleNotification = null);
                    },
                  ),
          ),
        ),
      ),
    ),
  );
  }
}


class _SmartGuidanceFloatingOverlay extends StatefulWidget {
  const _SmartGuidanceFloatingOverlay({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    required this.managerTeamId,
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String managerTeamId;

  @override
  State<_SmartGuidanceFloatingOverlay> createState() =>
      _SmartGuidanceFloatingOverlayState();
}

class _SmartGuidanceFloatingOverlayState
    extends State<_SmartGuidanceFloatingOverlay> {
  static const String _consumerKey = 'smart-guidance-overlay';
  final math.Random _random = math.Random();
  Timer? _showTimer;
  Timer? _hideTimer;
  AttentionReminder? _visibleReminder;
  bool _visible = false;
  bool _attentionRequested = false;
  int _lastSignatureHash = 0;
  final Set<String> _shownReminderIds = <String>{};
  AttentionReminderType? _lastReminderType;

  @override
  void initState() {
    super.initState();
    _scheduleNext(initial: true);
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _releaseGuidanceAttention();
    super.dispose();
  }

  void _handleState(NotificationsState state) {
    final signature = state.reminders.map((item) => item.id).join('|').hashCode;
    if (signature != _lastSignatureHash) {
      _lastSignatureHash = signature;
      if (!_visible) {
        if (_attentionRequested) {
          _scheduleAfter(const Duration(milliseconds: 600));
        } else {
          _scheduleNext(initial: _lastSignatureHash == 0);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Positioned.fill(
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: isMobile ? AppSpacing.sm : AppSpacing.xl,
              right: isMobile ? AppSpacing.sm : 0,
            ),
            child: BlocListener<NotificationsCubit, NotificationsState>(
              listenWhen: (previous, current) =>
                  previous.reminders != current.reminders,
              listener: (context, state) => _handleState(state),
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                buildWhen: (previous, current) =>
                    previous.reminders != current.reminders,
                builder: (context, state) {
                  return IgnorePointer(
                    ignoring: !_visible || _visibleReminder == null,
                    child: AnimatedOpacity(
                      opacity: _visible && _visibleReminder != null ? 1 : 0,
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: AnimatedSlide(
                        offset: _visible || reducedMotion
                            ? Offset.zero
                            : const Offset(-0.08, 0),
                        duration: reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: _visibleReminder == null
                            ? const SizedBox.shrink()
                            : _SmartGuidanceCard(
                                reminder: _visibleReminder!,
                                onClose: _dismiss,
                                onOpen: () =>
                                    _openReminder(context, _visibleReminder!),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleNext({required bool initial}) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (!mounted) {
      return;
    }
    // Keep smart guidance useful and frequent enough to matter without
    // becoming spam. Rotate with a random delay between 5 and 15 minutes.
    final delay = Duration(minutes: 5 + _random.nextInt(11));
    _scheduleAfter(delay);
  }

  void _scheduleAfter(Duration delay) {
    _showTimer?.cancel();
    if (!mounted) {
      return;
    }
    _showTimer = Timer(delay, _showNextReminder);
  }

  void _requestGuidanceAttention() {
    if (_attentionRequested || !mounted) {
      return;
    }
    _attentionRequested = true;
    context.read<NotificationsCubit>().watchAttentionReminders(
          consumerKey: _consumerKey,
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
          remindersLimit: 18,
        );
  }

  void _releaseGuidanceAttention() {
    if (!_attentionRequested || !mounted) {
      return;
    }
    _attentionRequested = false;
    context.read<NotificationsCubit>().releaseAttentionReminders(_consumerKey);
  }

  List<AttentionReminder> _availableReminders() {
    final state = context.read<NotificationsCubit>().state;
    final reminders = state.reminders
        .where((item) =>
            item.route.trim().isNotEmpty && !_shownReminderIds.contains(item.id))
        .toList();
    reminders.sort(_compareGuidanceReminderPriority);
    return reminders.take(18).toList();
  }

  AttentionReminder? _pickNextReminder(List<AttentionReminder> reminders) {
    if (reminders.isEmpty) {
      return null;
    }
    final grouped = <AttentionReminderType, List<AttentionReminder>>{};
    for (final reminder in reminders) {
      grouped.putIfAbsent(reminder.type, () => <AttentionReminder>[]).add(reminder);
    }
    final types = grouped.keys.toList()
      ..sort((a, b) => _reminderRankByType(a).compareTo(_reminderRankByType(b)));
    var selectedType = types.first;
    if (_lastReminderType != null && types.length > 1) {
      selectedType = types.firstWhere(
        (type) => type != _lastReminderType,
        orElse: () => types.first,
      );
    }
    final candidates = grouped[selectedType]!..sort(_compareGuidanceReminderPriority);
    return candidates.first;
  }

  void _rememberShownReminder(AttentionReminder reminder) {
    _shownReminderIds.add(reminder.id);
    _lastReminderType = reminder.type;
  }

  void _showNextReminder() {
    if (!mounted || _visible) {
      return;
    }
    final reminders = _availableReminders();
    if (reminders.isEmpty && !_attentionRequested) {
      _requestGuidanceAttention();
      _scheduleAfter(const Duration(seconds: 8));
      return;
    }
    final reminder = _pickNextReminder(reminders);
    if (reminder == null) {
      _releaseGuidanceAttention();
      _scheduleNext(initial: false);
      return;
    }
    setState(() {
      _visibleReminder = reminder;
      _visible = true;
    });
    _releaseGuidanceAttention();
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) {
        return;
      }
      final reminder = _visibleReminder;
      if (reminder != null) {
        _rememberShownReminder(reminder);
        context.read<NotificationsCubit>().clearAttentionReminder(reminder.id);
      }
      setState(() => _visible = false);
      _scheduleNext(initial: false);
    });
  }

  void _dismiss() {
    _hideTimer?.cancel();
    if (!mounted) {
      return;
    }
    final reminder = _visibleReminder;
    if (reminder != null) {
      _rememberShownReminder(reminder);
      context.read<NotificationsCubit>().clearAttentionReminder(reminder.id);
    }
    setState(() => _visible = false);
    _scheduleNext(initial: false);
  }

  void _openReminder(BuildContext context, AttentionReminder reminder) {
    _hideTimer?.cancel();
    _rememberShownReminder(reminder);
    context.read<NotificationsCubit>().clearAttentionReminder(reminder.id);
    if (mounted) {
      setState(() => _visible = false);
    }
    final route = reminder.route.trim();
    if (route.isNotEmpty) {
      context.go(route);
    }
    if (mounted) {
      _scheduleNext(initial: false);
    }
  }
}

class _SmartGuidanceCard extends StatelessWidget {
  const _SmartGuidanceCard({
    required this.reminder,
    required this.onClose,
    required this.onOpen,
  });

  final AttentionReminder reminder;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final color = _reminderToneColor(context, reminder.type);
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? MediaQuery.sizeOf(context).width - 32 : 380,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.chromeSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.30)),
            boxShadow: AppShadows.shell,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_reminderIcon(reminder.type), color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _guidanceTitle(l, reminder),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _guidanceBody(l, reminder),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                TextButton(
                  onPressed: onOpen,
                  child: Text(l.open),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _guidanceTitle(AppLocalizations l, AttentionReminder reminder) {
  return switch (reminder.type) {
    AttentionReminderType.followUpOverdue => l.notificationFollowUpOverdueTitle,
    AttentionReminderType.followUpDueToday => l.notificationFollowUpDueTodayTitle,
    AttentionReminderType.taskOverdue => l.notificationTaskOverdueTitle,
    AttentionReminderType.taskDueToday => l.notificationTaskDueTodayTitle,
    AttentionReminderType.appointmentMissed => l.appointmentMissed,
    AttentionReminderType.appointmentDueNow => l.salesCommandReasonAppointmentDueNow,
    AttentionReminderType.appointmentUpcomingSoon ||
    AttentionReminderType.appointmentToday => l.appointments,
    AttentionReminderType.unassignedLead => l.unassignedLeads,
  };
}

String _guidanceBody(AppLocalizations l, AttentionReminder reminder) {
  final title = reminder.recordTitle.trim().isEmpty
      ? reminder.recordSubtitle.trim()
      : reminder.recordTitle.trim();
  final cleanTitle = title.isEmpty ? l.viewDetails : title;
  return switch (reminder.type) {
    AttentionReminderType.followUpOverdue =>
      '${l.salesCommandWhyOverdueFollowUp} • $cleanTitle',
    AttentionReminderType.followUpDueToday =>
      '${l.salesCommandWhyDueTodayFollowUp} • $cleanTitle',
    AttentionReminderType.taskOverdue =>
      '${l.salesCommandWhyOverdueTask} • $cleanTitle',
    AttentionReminderType.taskDueToday =>
      '${l.salesCommandWhyDueTodayTask} • $cleanTitle',
    AttentionReminderType.appointmentMissed =>
      '${l.salesCommandReasonAppointmentMissed} • $cleanTitle',
    AttentionReminderType.appointmentDueNow =>
      '${l.salesCommandReasonAppointmentDueNow} • $cleanTitle',
    AttentionReminderType.appointmentUpcomingSoon ||
    AttentionReminderType.appointmentToday =>
      '${l.newAppointment} • $cleanTitle',
    AttentionReminderType.unassignedLead =>
      '${l.salesCommandWhyUnassignedLead} • $cleanTitle',
  };
}

Color _reminderToneColor(BuildContext context, AttentionReminderType type) {
  return switch (type) {
    AttentionReminderType.followUpOverdue ||
    AttentionReminderType.taskOverdue ||
    AttentionReminderType.appointmentMissed => AppColors.errorColor(context),
    AttentionReminderType.followUpDueToday ||
    AttentionReminderType.taskDueToday ||
    AttentionReminderType.appointmentDueNow => AppColors.warningColor(context),
    AttentionReminderType.unassignedLead => AppColors.infoColor(context),
    _ => AppColors.primaryColor(context),
  };
}

IconData _reminderIcon(AttentionReminderType type) {
  return switch (type) {
    AttentionReminderType.followUpOverdue ||
    AttentionReminderType.followUpDueToday => Icons.phone_in_talk_outlined,
    AttentionReminderType.taskOverdue ||
    AttentionReminderType.taskDueToday => Icons.assignment_late_outlined,
    AttentionReminderType.appointmentMissed ||
    AttentionReminderType.appointmentDueNow ||
    AttentionReminderType.appointmentUpcomingSoon ||
    AttentionReminderType.appointmentToday => Icons.event_available_outlined,
    AttentionReminderType.unassignedLead => Icons.person_search_outlined,
  };
}

int _compareGuidanceReminderPriority(AttentionReminder a, AttentionReminder b) {
  final rankCompare = _reminderRank(a).compareTo(_reminderRank(b));
  if (rankCompare != 0) {
    return rankCompare;
  }
  final aDate = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final dateCompare = aDate.compareTo(bDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  return a.id.compareTo(b.id);
}

int _reminderRankByType(AttentionReminderType type) {
  return switch (type) {
    AttentionReminderType.appointmentMissed => 0,
    AttentionReminderType.appointmentDueNow => 1,
    AttentionReminderType.followUpOverdue => 2,
    AttentionReminderType.taskOverdue => 3,
    AttentionReminderType.unassignedLead => 4,
    AttentionReminderType.appointmentUpcomingSoon => 5,
    AttentionReminderType.appointmentToday => 6,
    AttentionReminderType.followUpDueToday => 7,
    AttentionReminderType.taskDueToday => 8,
  };
}

int _reminderRank(AttentionReminder reminder) {
  return _reminderRankByType(reminder.type);
}


class _NotificationToastCard extends StatelessWidget {
  const _NotificationToastCard({
    super.key,
    required this.companyId,
    required this.notification,
    required this.onClose,
  });

  final String companyId;
  final CrmNotification notification;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? MediaQuery.sizeOf(context).width - 32 : 360,
        ),
        child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await context.read<NotificationsCubit>().markAsRead(
                    companyId: companyId,
                    notification: notification,
                  );
              onClose();
              if (context.mounted) {
                final resolution = NotificationRouteResolver.resolve(notification);
                context.go(resolution.route);
              }
            },
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: colors.chromeSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
                boxShadow: AppShadows.shell,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notificationTitle(l, notification),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notificationBody(l, notification),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: '',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

bool _isNavigationItemEnabled(
  CompanyMetadata? companyMetadata,
  CrmNavigationItem item,
) {
  final feature = _featureForNavigationItem(item);
  if (feature == null) {
    return true;
  }
  return companyMetadata.isFeatureEnabled(feature);
}

CompanyFeature? _featureForNavigationItem(CrmNavigationItem item) {
  return switch (item) {
    CrmNavigationItem.dashboard => null,
    CrmNavigationItem.leads => CompanyFeature.leads,
    CrmNavigationItem.properties => CompanyFeature.properties,
    CrmNavigationItem.clients => CompanyFeature.clients,
    CrmNavigationItem.tasks => CompanyFeature.tasks,
    CrmNavigationItem.appointments => CompanyFeature.appointments,
    CrmNavigationItem.deals => CompanyFeature.deals,
    CrmNavigationItem.reports => CompanyFeature.reports,
    CrmNavigationItem.auditLogs => CompanyFeature.auditLogs,
    CrmNavigationItem.users => CompanyFeature.userManagement,
    CrmNavigationItem.teams => null,
    CrmNavigationItem.dataHealth => null,
    CrmNavigationItem.support => null,
    CrmNavigationItem.more => null,
  };
}

void _goToItem(BuildContext context, CrmNavigationItem item) {
  final authState = context.read<AuthBloc>().state;
  if (!_isNavigationItemEnabled(authState.companyMetadata, item)) {
    AppFeedback.error(
      context,
      AppLocalizations.of(context)!.featureNotEnabledForWorkspace,
    );
    return;
  }

  switch (item) {
    case CrmNavigationItem.dashboard:
      context.go(RouteNames.dashboard);
    case CrmNavigationItem.leads:
      context.go(RouteNames.leads);
    case CrmNavigationItem.properties:
      context.go(RouteNames.properties);
    case CrmNavigationItem.clients:
      context.go(RouteNames.clients);
    case CrmNavigationItem.tasks:
      context.go(RouteNames.tasks);
    case CrmNavigationItem.appointments:
      context.go(RouteNames.appointments);
    case CrmNavigationItem.deals:
      context.go(RouteNames.deals);
    case CrmNavigationItem.reports:
      context.go(RouteNames.reports);
    case CrmNavigationItem.auditLogs:
      context.go(RouteNames.auditLogs);
    case CrmNavigationItem.users:
      context.go(RouteNames.users);
    case CrmNavigationItem.teams:
      context.go(RouteNames.teams);
    case CrmNavigationItem.dataHealth:
      context.go(RouteNames.dataHealth);
    case CrmNavigationItem.support:
      context.go(RouteNames.support);
    case CrmNavigationItem.more:
      break;
  }
}

List<_CrmShellItem> _visibleItemsForRole(
  List<_CrmShellItem> items,
  UserRole? role,
) {
  return items.where((item) {
    if (item.item == CrmNavigationItem.users) {
      return role == UserRole.admin;
    }
    if (item.item == CrmNavigationItem.auditLogs) {
      return role == UserRole.admin || role == UserRole.manager;
    }
    if (item.item == CrmNavigationItem.teams) {
      return role == UserRole.admin || role == UserRole.manager;
    }
    if (item.item == CrmNavigationItem.dataHealth) {
      return role == UserRole.admin;
    }
    if (item.item == CrmNavigationItem.appointments) {
      return role != UserRole.viewer;
    }
    return true;
  }).toList();
}

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({
    required this.selectedItem,
    required this.items,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _isSidebarCollapsed = false;
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: _WorkspaceBackground(
        intense: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _Sidebar(
                selectedItem: widget.selectedItem,
                items: widget.items,
                isCollapsed: _isSidebarCollapsed,
                onToggleCollapsed: () {
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                },
                scrollController: _sidebarScrollController,
                onItemSelected: widget.onItemSelected,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: widget.title ??
                          _labelFor(context, widget.selectedItem),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverseDuration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (incoming, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: AnimatedBuilder(
                              animation: curved,
                              child: incoming,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, (1 - curved.value) * 14),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          key: ValueKey(widget.selectedItem),
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.sm,
                            0,
                            AppSpacing.sm,
                            AppSpacing.sm,
                          ),
                          child: PrimaryScrollController(
                            controller: _mainScrollController,
                            child: _ShellRefreshWrapper(child: widget.child),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceBackground extends StatelessWidget {
  const _WorkspaceBackground({required this.child, this.intense = false});

  final Widget child;
  final bool intense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.appBackground(context);
    final isMobileWeb = kIsWeb && MediaQuery.sizeOf(context).width < 720;
    if (isMobileWeb) {
      return ColoredBox(color: base, child: child);
    }
    final warmTint = isDark ? AppColors.darkCardSurface : AppColors.backgroundSoft;
    final highlight = isDark ? AppColors.darkPrimary : AppColors.backgroundHighlight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
          radius: intense ? 1.18 : 0.82,
          colors: [
            highlight.withValues(alpha: isDark ? 0.065 : 0.88),
            warmTint.withValues(alpha: isDark ? 0.10 : 0.62),
            base,
          ],
          stops: const [0, 0.46, 1],
        ),
      ),
      child: CustomPaint(
        painter: _WorkspacePatternPainter(
          color: isDark
              ? AppColors.darkTextPrimary.withValues(
                  alpha: intense ? 0.018 : 0.010,
                )
              : AppColors.shellBorder.withValues(
                  alpha: intense ? 0.22 : 0.12,
                ),
          compact: !intense,
        ),
        child: child,
      ),
    );
  }
}

class _WorkspacePatternPainter extends CustomPainter {
  const _WorkspacePatternPainter({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final step = compact ? 36.0 : 28.0;

    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), compact ? 0.7 : 0.9, paint);
      }
    }

    if (!compact) {
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.26)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(size.width * 0.86, 0),
        Offset(size.width, size.height * 0.16),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.90, size.height),
        Offset(size.width, size.height * 0.84),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkspacePatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.compact != compact;
  }
}

class _MobileShell extends StatefulWidget {
  const _MobileShell({
    required this.selectedItem,
    required this.items,
    required this.companyMetadata,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final CompanyMetadata? companyMetadata;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  static const _scrollThreshold = 72.0;

  bool _showBottomNavigation = true;
  bool _modalOpen = false;
  double _scrollDelta = 0;

  Future<void> _openMoreSheet() async {
    setState(() {
      _modalOpen = true;
      _showBottomNavigation = true;
    });
    await _showMobileMoreSheet(context);
    if (mounted) {
      setState(() => _modalOpen = false);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical || _modalOpen) {
      return false;
    }

    if (FocusManager.instance.primaryFocus != null ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      _showNavigationIfNeeded();
      return false;
    }

    if (notification.metrics.pixels <= notification.metrics.minScrollExtent + 8) {
      _scrollDelta = 0;
      _showNavigationIfNeeded();
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) {
        return false;
      }
      if ((_scrollDelta > 0 && delta < 0) || (_scrollDelta < 0 && delta > 0)) {
        _scrollDelta = 0;
      }
      _scrollDelta += delta;

      if (_scrollDelta > _scrollThreshold && _showBottomNavigation) {
        setState(() => _showBottomNavigation = false);
        _scrollDelta = 0;
      } else if (_scrollDelta < -_scrollThreshold && !_showBottomNavigation) {
        setState(() => _showBottomNavigation = true);
        _scrollDelta = 0;
      }
    }

    return false;
  }

  void _showNavigationIfNeeded() {
    if (!_showBottomNavigation) {
      setState(() => _showBottomNavigation = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final effectiveShowBottomNavigation =
        _showBottomNavigation || MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleSpacing: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: _MobileHeaderCard(
            title: widget.title ?? _labelFor(context, widget.selectedItem),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: _WorkspaceBackground(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (incoming, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: AnimatedBuilder(
                      animation: curved,
                      child: incoming,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, (1 - curved.value) * 14),
                        child: child,
                      ),
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('mobile-page-${widget.selectedItem.name}'),
                  child: _ShellRefreshWrapper(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutQuart,
        offset: effectiveShowBottomNavigation ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: effectiveShowBottomNavigation ? 1 : 0,
          child: IgnorePointer(
            ignoring: !effectiveShowBottomNavigation,
            child: _MobileBottomNavigation(
              selectedItem: widget.selectedItem,
              items: widget.items,
              companyMetadata: widget.companyMetadata,
              onItemSelected: (item) {
                if (item == CrmNavigationItem.more) {
                  _openMoreSheet();
                  return;
                }
                widget.onItemSelected?.call(item);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalShellBlur extends StatelessWidget {
  const _OptionalShellBlur({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: child,
    );
  }
}

class _MobileHeaderCard extends StatelessWidget {
  const _MobileHeaderCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.userProfile?.fullName != current.userProfile?.fullName ||
          previous.user?.fullName != current.user?.fullName ||
          previous.userProfile?.photoUrl != current.userProfile?.photoUrl ||
          previous.userProfile?.photoStoragePath !=
              current.userProfile?.photoStoragePath ||
          previous.userProfile?.updatedAt != current.userProfile?.updatedAt ||
          previous.user?.photoUrl != current.user?.photoUrl,
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        final fullName = _resolvedUserName(state, localizations.crmUser);
        final photoUrl = _resolvedUserPhotoUrl(state);
        _debugProfileImageSources(state, 'mobile shell avatar');

        return Material(
          color: colors.chromeSurface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(26),
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            child: Row(
              children: [
                Tooltip(
                  message: localizations.profile,
                  child: const _ProfileMenuButton(compact: true),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const _MobileSearchIconButton(),
                const SizedBox(width: AppSpacing.xs),
                const _NotificationIconButton(compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileBottomNavigation extends StatefulWidget {
  const _MobileBottomNavigation({
    required this.selectedItem,
    required this.items,
    required this.companyMetadata,
    required this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final CompanyMetadata? companyMetadata;
  final ValueChanged<CrmNavigationItem> onItemSelected;

  @override
  State<_MobileBottomNavigation> createState() =>
      _MobileBottomNavigationState();
}

class _MobileBottomNavigationState extends State<_MobileBottomNavigation> {
  late CrmNavigationItem _optimisticSelectedItem;

  @override
  void initState() {
    super.initState();
    _optimisticSelectedItem = widget.selectedItem;
  }

  @override
  void didUpdateWidget(covariant _MobileBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem != widget.selectedItem ||
        oldWidget.items != widget.items) {
      _optimisticSelectedItem = widget.selectedItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primaryColor(context);
    final selectedForeground = isDark ? const Color(0xFF050505) : AppColors.textStrong;
    final navSurface = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.94)
        : colors.chromeSurface.withValues(alpha: 0.98);
    final isMobileWeb = kIsWeb && MediaQuery.sizeOf(context).width < 720;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: _OptionalShellBlur(
            enabled: !isMobileWeb,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 64,
                maxHeight: 72,
              ),
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(7, 7, 7, 7),
              decoration: BoxDecoration(
                color: navSurface,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : colors.border,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: isMobileWeb
                    ? null
                    : isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : AppShadows.shell,
              ),
              child: Row(
                children: [
                  for (final item in widget.items)
                    Expanded(
                      flex: _isMobileItemSelected(item.item) ? 3 : 1,
                      child: _PremiumMobileNavItem(
                        item: item,
                        selected: _isMobileItemSelected(item.item),
                        enabled: _isNavigationItemEnabled(
                          widget.companyMetadata,
                          item.item,
                        ),
                        primary: primary,
                        selectedForeground: selectedForeground,
                        colors: colors,
                        onTap: () {
                          if (!_isNavigationItemEnabled(
                            widget.companyMetadata,
                            item.item,
                          )) {
                            return;
                          }
                          setState(() => _optimisticSelectedItem = item.item);
                          widget.onItemSelected(item.item);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isMobileItemSelected(CrmNavigationItem item) {
    if (item == _optimisticSelectedItem) {
      return true;
    }
    return item == CrmNavigationItem.more &&
        (_optimisticSelectedItem == CrmNavigationItem.tasks ||
            _optimisticSelectedItem == CrmNavigationItem.appointments ||
            _optimisticSelectedItem == CrmNavigationItem.deals ||
            _optimisticSelectedItem == CrmNavigationItem.reports ||
            _optimisticSelectedItem == CrmNavigationItem.auditLogs ||
            _optimisticSelectedItem == CrmNavigationItem.users ||
            _optimisticSelectedItem == CrmNavigationItem.teams ||
            _optimisticSelectedItem == CrmNavigationItem.dataHealth ||
            _optimisticSelectedItem == CrmNavigationItem.support);
  }
}

class _PremiumMobileNavItem extends StatelessWidget {
  const _PremiumMobileNavItem({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.primary,
    required this.selectedForeground,
    required this.colors,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool enabled;
  final Color primary;
  final Color selectedForeground;
  final _CrmShellColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = item.label(context);
    final icon = enabled
        ? (selected ? item.selectedIcon : item.icon)
        : Icons.lock_outline;
    final foreground = !enabled
        ? colors.textSecondary.withValues(alpha: 0.42)
        : selected
            ? selectedForeground
            : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: EdgeInsetsDirectional.only(
                start: selected ? 10 : 0,
                end: selected ? 10 : 0,
              ),
              decoration: BoxDecoration(
                color: selected ? primary.withValues(alpha: 0.96) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: selected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 20, color: foreground),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Icon(icon, size: 20, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItemButton extends StatelessWidget {
  const _MobileNavItemButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = !enabled
        ? colors.textSecondary.withValues(alpha: 0.42)
        : selected
            ? (isDark ? Colors.black : AppColors.textStrong)
            : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : colors.primary.withValues(alpha: 0.34),
                      )
                    : null,
                boxShadow: selected && isDark
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                scale: selected ? 1 : 0.96,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      enabled
                          ? (selected ? item.selectedIcon : item.icon)
                          : Icons.lock_outline,
                      size: selected ? 21 : 22,
                      color: foreground,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontSize: selected ? 10.5 : 10,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                        height: 1,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showMobileMoreSheet(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  final companyMetadata = authState.companyMetadata;
  final role = authState.protectedCompanySession?.profile.role;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    showDragHandle: false,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final localizations = AppLocalizations.of(sheetContext)!;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: _CrmShellColors.of(sheetContext).chromeSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: _CrmShellColors.of(sheetContext).textSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _MoreSheetTile(
                  icon: Icons.checklist_outlined,
                  label: localizations.tasks,
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.tasks),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.tasks);
                  },
                ),
                if (role != UserRole.viewer)
                  _MoreSheetTile(
                    icon: Icons.event_note_outlined,
                    label: localizations.appointments,
                    enabled: companyMetadata.isFeatureEnabled(
                      CompanyFeature.appointments,
                    ),
                    disabledSubtitle: localizations.moduleDisabled,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.appointments);
                    },
                  ),
                _MoreSheetTile(
                  icon: Icons.handshake_outlined,
                  label: localizations.deals,
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.deals),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.deals);
                  },
                ),
                _MoreSheetTile(
                  icon: Icons.bar_chart_outlined,
                  label: localizations.reports,
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.reports),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.reports);
                  },
                ),
                if (role == UserRole.admin || role == UserRole.manager)
                  _MoreSheetTile(
                    icon: Icons.manage_search_outlined,
                    label: localizations.auditLogs,
                    enabled: companyMetadata.isFeatureEnabled(
                      CompanyFeature.auditLogs,
                    ),
                    disabledSubtitle: localizations.moduleDisabled,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.auditLogs);
                    },
                  ),
                if (role == UserRole.admin)
                  _MoreSheetTile(
                    icon: Icons.manage_accounts_outlined,
                    label: localizations.userManagement,
                    enabled: companyMetadata.isFeatureEnabled(
                      CompanyFeature.userManagement,
                    ),
                    disabledSubtitle: localizations.moduleDisabled,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.users);
                    },
                  ),
                if (role == UserRole.admin || role == UserRole.manager)
                  _MoreSheetTile(
                    icon: Icons.groups_outlined,
                    label: localizations.teamManagement,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.teams);
                    },
                  ),
                if (role == UserRole.admin)
                  _MoreSheetTile(
                    icon: Icons.health_and_safety_outlined,
                    label: localizations.dataHealth,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.dataHealth);
                    },
                  ),
                _MoreSheetTile(
                  icon: Icons.support_agent_outlined,
                  label: localizations.supportCenter,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.support);
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
    },
  );
}

class _MoreSheetTile extends StatelessWidget {
  const _MoreSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.disabledSubtitle,
    this.enabled = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final String? disabledSubtitle;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final effectiveColor = !enabled
        ? colors.textSecondary.withValues(alpha: 0.55)
        : isDestructive
            ? colors.error
            : colors.textPrimary;
    final effectiveSubtitle = enabled ? subtitle : disabledSubtitle ?? subtitle;

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        enabled: enabled,
        leading: Icon(enabled ? icon : Icons.lock_outline, color: effectiveColor),
        title: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
        ),
        subtitle: effectiveSubtitle == null
            ? null
            : Text(
                effectiveSubtitle,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(color: colors.textSecondary),
              ),
        onTap: enabled ? onTap : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _LanguageSheetActions extends StatelessWidget {
  const _LanguageSheetActions({required this.localeCubit});

  final LocaleCubit localeCubit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<LocaleCubit, Locale?>(
      bloc: localeCubit,
      builder: (context, locale) {
        final selectedLanguage = locale?.languageCode ?? 'en';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                localizations.language,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _CrmShellColors.of(context).textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _LanguageChoiceButton(
                    label: localizations.english,
                    selected: selectedLanguage == 'en',
                    onTap: () {
                      Navigator.of(context).pop();
                      localeCubit.setEnglish();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LanguageChoiceButton(
                    label: localizations.arabic,
                    selected: selectedLanguage == 'ar',
                    onTap: () {
                      Navigator.of(context).pop();
                      localeCubit.setArabic();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
class _LanguageChoiceButton extends StatelessWidget {
  const _LanguageChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? _CrmShellColors.of(context).selectedSurface
            : _CrmShellColors.of(context).cardSurface,
        foregroundColor: selected
            ? _CrmShellColors.of(context).primary
            : _CrmShellColors.of(context).textPrimary,
        side: BorderSide(
          color: selected
              ? _CrmShellColors.of(context).primary
              : _CrmShellColors.of(context).border,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedItem,
    required this.items,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    required this.scrollController,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;
  final ScrollController scrollController;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      width: isCollapsed ? 76 : 262,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_sidebarColor(context), _sidebarRaisedColor(context)],
        ),
        borderRadius: _sidebarRadius(context),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.shellBorder,
        ),
        boxShadow: isDark ? null : AppShadows.shell,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: isCollapsed
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  _BrandHeader(isCollapsed: isCollapsed),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: !isCollapsed,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        primary: false,
                        child: Column(
                        children: [
                          for (final item in items)
                            _SidebarItem(
                              item: item,
                              selected: item.item == selectedItem,
                              enabled: _isNavigationItemEnabled(
                                context.select(
                                  (AuthBloc bloc) => bloc.state.companyMetadata,
                                ),
                                item.item,
                              ),
                              isCollapsed: isCollapsed,
                              onTap: () => onItemSelected?.call(item.item),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 76,
            end: -15,
            child: _SidebarUtilities(
              isCollapsed: isCollapsed,
              onToggleCollapsed: onToggleCollapsed,
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _sidebarRadius(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return BorderRadiusDirectional.only(
      topStart: const Radius.circular(30),
      bottomStart: const Radius.circular(30),
      topEnd: Radius.circular(isRtl ? 30 : 38),
      bottomEnd: Radius.circular(isRtl ? 30 : 38),
    ).resolve(Directionality.of(context));
  }

  Color _sidebarColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShell : AppColors.shell;
  }

  Color _sidebarRaisedColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShellRaised : AppColors.shellRaised;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandTextColor = isDark ? AppColors.darkTextPrimary : AppColors.shellText;
    final brandMutedColor =
    isDark ? AppColors.darkTextSecondary : AppColors.shellTextMuted;

    final mark = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkShellRaised : AppColors.primaryLight,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primaryBorder.withValues(alpha: 0.7),
        ),
      ),
      child: const MasarBrandMark(size: 30),
    );

    if (isCollapsed) {
      return Tooltip(
        message: AppLocalizations.of(context)!.appName,
        child: mark,
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 2, AppSpacing.xs),
      child: Row(
        children: [
          mark,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                      color: brandTextColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.salesWorkspace,
                  maxLines: 2,
                  softWrap: true,
                  style: textTheme.bodySmall?.copyWith(
                      color: brandMutedColor,
                      height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.isCollapsed,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool enabled;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTextColor = isDark ? Colors.black : AppColors.shellText;
    final inactiveTextColor =
    isDark ? AppColors.darkTextSecondary : AppColors.shellTextMuted;
    final color = !enabled
        ? inactiveTextColor.withValues(alpha: 0.48)
        : selected
            ? selectedTextColor
            : inactiveTextColor;
    final label = item.label(context);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(
        isCollapsed ? 0 : AppSpacing.sm,
        11,
        isCollapsed ? 0 : AppSpacing.sm,
        11,
      ),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? AppColors.darkPrimary : AppColors.shellActive)
            : Colors.transparent,
        borderRadius: AppRadius.large,
        border: selected
            ? Border.all(
          color: isDark
              ? AppColors.darkPrimaryHover.withValues(alpha: 0.28)
              : AppColors.primaryPressed.withValues(alpha: 0.18),
        )
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            enabled ? (selected ? item.selectedIcon : item.icon) : Icons.lock_outline,
            color: color,
            size: 20,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (!enabled)
              Icon(
                Icons.lock_outline,
                size: 14,
                color: color,
              ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: isCollapsed ? label : '',
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.large,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.large,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SidebarUtilities extends StatelessWidget {
  const _SidebarUtilities({
    required this.isCollapsed,
    required this.onToggleCollapsed,
  });

  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    final collapseIcon = isCollapsed
        ? (textDirection == TextDirection.rtl
            ? Icons.keyboard_double_arrow_left
            : Icons.keyboard_double_arrow_right)
        : (textDirection == TextDirection.rtl
            ? Icons.keyboard_double_arrow_right
            : Icons.keyboard_double_arrow_left);

    return Align(
      alignment: AlignmentDirectional.center,
      child: _SidebarUtilityButton(
        icon: collapseIcon,
        label: localizations.more,
        isCollapsed: true,
        showLabel: false,
        onTap: onToggleCollapsed,
      ),
    );
  }
}

class _SidebarUtilityButton extends StatelessWidget {
  const _SidebarUtilityButton({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    this.onTap,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkPrimary : AppColors.primaryDeep;
    final compact = isCollapsed || !showLabel;
    final content = Container(
      width: compact ? 38 : double.infinity,
      height: compact ? 38 : null,
      padding: EdgeInsetsDirectional.fromSTEB(
        compact ? 0 : AppSpacing.sm,
        compact ? 0 : 10,
        compact ? 0 : AppSpacing.sm,
        compact ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkShellRaised : AppColors.shellRaised,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.shellBorder,
        ),
        borderRadius: compact ? AppRadius.medium : AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          if (!isCollapsed && showLabel) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: isCollapsed || !showLabel ? label : '',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: content,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.chromeSurface.withValues(alpha: 0.94),
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.xLarge,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          return Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!compact) ...[
                Flexible(
                  child: TextField(
                    readOnly: true,
                    textInputAction: TextInputAction.search,
                    onTap: () => _showGlobalSearchDialog(context),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchCrm,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const _TopBarCreateButton(),
                ],
              ],
              const SizedBox(width: AppSpacing.sm),
              const _NotificationIconButton(),
              const SizedBox(width: AppSpacing.xs),
              const _LanguageMenuButton(),
              const _ThemeToggleButton(),
              //const _LogoutIconButton(),
              const SizedBox(width: AppSpacing.sm),
              const _ProfileMenuButton(),
            ],
          );
        },
      ),
    );
  }
}

class _TopBarCreateButton extends StatelessWidget {
  const _TopBarCreateButton();

  @override
  Widget build(BuildContext context) {
    final actions = _topBarCreateActions(context);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = _CrmShellColors.of(context);
    final primary = AppColors.primaryColor(context);
    return PopupMenuButton<_CreateAction>(
      tooltip: AppLocalizations.of(context)!.dashboardQuickAction,
      position: PopupMenuPosition.under,
      onSelected: (action) => context.go(action.route),
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem<_CreateAction>(
            value: action,
            child: Row(
              children: [
                Icon(action.icon, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(action.label)),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _CreateAction {
  const _CreateAction({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

List<_CreateAction> _topBarCreateActions(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final authState = context.read<AuthBloc>().state;
  final role = authState.protectedCompanySession?.profile.role;
  final company = authState.companyMetadata;
  if (role == null) {
    return const <_CreateAction>[];
  }
  return [
    if (company.isFeatureEnabled(CompanyFeature.leads) &&
        PermissionService.can(role, AppPermission.createLead))
      _CreateAction(label: l.dashboardAddLead, icon: Icons.person_add_alt_outlined, route: RouteNames.leadsCreate),
    if (company.isFeatureEnabled(CompanyFeature.clients) &&
        PermissionService.can(role, AppPermission.createClient))
      _CreateAction(label: l.dashboardAddClient, icon: Icons.group_add_outlined, route: RouteNames.clientsCreate),
    if (company.isFeatureEnabled(CompanyFeature.properties) &&
        PermissionService.can(role, AppPermission.createProperty))
      _CreateAction(label: l.dashboardAddProperty, icon: Icons.add_business_outlined, route: RouteNames.propertiesCreate),
    if (company.isFeatureEnabled(CompanyFeature.deals) &&
        PermissionService.can(role, AppPermission.createDeal))
      _CreateAction(label: l.createDeal, icon: Icons.handshake_outlined, route: RouteNames.dealsCreate),
    if (company.isFeatureEnabled(CompanyFeature.appointments) &&
        PermissionService.can(role, AppPermission.createAppointment))
      _CreateAction(label: l.dashboardAddAppointment, icon: Icons.event_available_outlined, route: RouteNames.appointmentsCreate),
  ];
}

class _ThemeSheetAction extends StatelessWidget {
  const _ThemeSheetAction({required this.themeCubit});

  final ThemeCubit themeCubit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;

        return Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: colors.textPrimary,
            ),
            title: Text(
              localizations.theme,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              isDark ? localizations.darkMode : localizations.lightMode,
              style: TextStyle(color: colors.textSecondary),
            ),
            trailing: Switch(
              value: isDark,
              activeThumbColor: colors.primary,
              activeTrackColor: colors.primary.withValues(alpha: 0.35),
              inactiveThumbColor: colors.textSecondary,
              inactiveTrackColor: colors.border,
              onChanged: (_) => themeCubit.toggle(),
            ),
            onTap: themeCubit.toggle,
          ),
        );
      },
    );
  }
}
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;

        return IconButton(
          tooltip: isDark ? localizations.lightMode : localizations.darkMode,
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        );
      },
    );
  }
}

class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: localizations.language,
      icon: const Icon(Icons.language),
      onSelected: (languageCode) {
        final localeCubit = context.read<LocaleCubit>();
        if (languageCode == 'ar') {
          localeCubit.setArabic();
        } else {
          localeCubit.setEnglish();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: 'en',
            child: Text(localizations.english),
          ),
          PopupMenuItem<String>(value: 'ar', child: Text(localizations.arabic)),
        ];
      },
    );
  }
}

class _AuthLogoutListener extends StatelessWidget {
  const _AuthLogoutListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return previous.status != current.status &&
            (current.status == AuthStatus.unauthenticated ||
                (current.status == AuthStatus.failure &&
                    previous.status == AuthStatus.loading &&
                    previous.user != null &&
                    current.user != null));
      },
      listener: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        if (state.status == AuthStatus.unauthenticated) {
          AppFeedback.success(context, localizations.loggedOutSuccessfully);
          context.go(RouteNames.login);
          return;
        }
        if (state.status == AuthStatus.failure) {
          AppFeedback.error(context, localizations.authErrorSignOutFailed);
        }
      },
      child: child,
    );
  }
}


class _MobileSearchIconButton extends StatelessWidget {
  const _MobileSearchIconButton();

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inputSurface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: AppLocalizations.of(context)!.searchCrm,
        onPressed: () => _showGlobalSearchDialog(context),
        icon: const Icon(Icons.search),
      ),
    );
  }
}

Future<void> _showGlobalSearchDialog(
  BuildContext context, {
  String initialQuery = '',
}) {
  final authState = context.read<AuthBloc>().state;
  final session = authState.protectedCompanySession;
  if (session == null) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l.searchCrm),
          content: Text(l.missingCompanyProfile),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  final repository = GlobalSearchRepositoryImpl(
    remoteDataSource: FirestoreGlobalSearchRemoteDataSource(),
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l = AppLocalizations.of(dialogContext)!;
      return BlocProvider(
        create: (_) => GlobalSearchCubit(
          searchGlobalDataUseCase: SearchGlobalDataUseCase(repository),
          companyId: session.companyId,
          currentUserId: session.uid,
          role: session.profile.role,
          includeUsers: session.profile.role == UserRole.admin ||
              session.profile.role == UserRole.manager,
          enabledModules: _enabledSearchModules(authState),
        )..queryChanged(initialQuery),
        child: AlertDialog(
          title: Text(l.searchCrm),
          content: _GlobalSearchDialogContent(
            initialQuery: initialQuery,
            onSelected: (result) {
              Navigator.of(dialogContext).pop();
              context.go(result.route);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    },
  );
}

class _GlobalSearchDialogContent extends StatefulWidget {
  const _GlobalSearchDialogContent({
    required this.initialQuery,
    required this.onSelected,
  });

  final String initialQuery;
  final ValueChanged<GlobalSearchResult> onSelected;

  @override
  State<_GlobalSearchDialogContent> createState() =>
      _GlobalSearchDialogContentState();
}

class _GlobalSearchDialogContentState extends State<_GlobalSearchDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      context.read<GlobalSearchCubit>().queryChanged(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.searchCrm,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: context.read<GlobalSearchCubit>().queryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
            builder: (context, state) {
              if (state.query.length < 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.searchCrm,
                    style: TextStyle(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                );
              }

              if (state.status == GlobalSearchStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: MasarLogoLoader(size: 34)),
                );
              }

              if (state.status == GlobalSearchStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.unableToConnect,
                    style: TextStyle(color: AppColors.errorColor(context)),
                  ),
                );
              }

              if (state.results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.noCompaniesFoundMessage,
                    style: TextStyle(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                );
              }

              final grouped = _groupSearchResults(state.results);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    return _GlobalSearchGroup(
                      module: entry.key,
                      results: entry.value,
                      onSelected: widget.onSelected,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<MapEntry<GlobalSearchModule, List<GlobalSearchResult>>> _groupSearchResults(
  List<GlobalSearchResult> results,
) {
  final grouped = <GlobalSearchModule, List<GlobalSearchResult>>{};
  for (final result in results) {
    grouped.putIfAbsent(result.module, () => []).add(result);
  }
  return grouped.entries.toList();
}

Set<GlobalSearchModule> _enabledSearchModules(AuthState authState) {
  final metadata = authState.companyMetadata;
  final role = authState.protectedCompanySession?.profile.role;
  return {
    if (metadata.isFeatureEnabled(CompanyFeature.leads))
      GlobalSearchModule.leads,
    if (metadata.isFeatureEnabled(CompanyFeature.clients))
      GlobalSearchModule.clients,
    if (metadata.isFeatureEnabled(CompanyFeature.properties))
      GlobalSearchModule.properties,
    if (metadata.isFeatureEnabled(CompanyFeature.deals))
      GlobalSearchModule.deals,
    if (metadata.isFeatureEnabled(CompanyFeature.tasks))
      GlobalSearchModule.tasks,
    if (role == UserRole.admin || role == UserRole.manager)
      GlobalSearchModule.users,
  };
}

class _GlobalSearchGroup extends StatelessWidget {
  const _GlobalSearchGroup({
    required this.module,
    required this.results,
    required this.onSelected,
  });

  final GlobalSearchModule module;
  final List<GlobalSearchResult> results;
  final ValueChanged<GlobalSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Text(
              _searchModuleLabel(context, module),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          for (final result in results)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              color: colors.inputSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.large,
                side: BorderSide(color: colors.border),
              ),
              child: ListTile(
                leading: Icon(_searchModuleIcon(module), color: colors.primary),
                title: Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  _searchSubtitle(result),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: result.status.trim().isEmpty
                    ? null
                    : Text(
                        result.status,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                onTap: () => onSelected(result),
              ),
            ),
        ],
      ),
    );
  }
}

String _searchSubtitle(GlobalSearchResult result) {
  final parts = [
    result.subtitle,
    result.owner,
  ].where((part) => part.trim().isNotEmpty).toList();
  return parts.isEmpty ? result.route : parts.join(' - ');
}

String _searchModuleLabel(BuildContext context, GlobalSearchModule module) {
  final l = AppLocalizations.of(context)!;
  return switch (module) {
    GlobalSearchModule.leads => l.leads,
    GlobalSearchModule.clients => l.clients,
    GlobalSearchModule.properties => l.properties,
    GlobalSearchModule.deals => l.deals,
    GlobalSearchModule.tasks => l.tasks,
    GlobalSearchModule.users => l.teamMembers,
  };
}

IconData _searchModuleIcon(GlobalSearchModule module) {
  return switch (module) {
    GlobalSearchModule.leads => Icons.people_alt_outlined,
    GlobalSearchModule.clients => Icons.person_outline,
    GlobalSearchModule.properties => Icons.business_outlined,
    GlobalSearchModule.deals => Icons.handshake_outlined,
    GlobalSearchModule.tasks => Icons.checklist_outlined,
    GlobalSearchModule.users => Icons.badge_outlined,
  };
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (!authState.companyMetadata.isFeatureEnabled(CompanyFeature.notifications)) {
      return const SizedBox.shrink();
    }
    return NotificationBellButton(compact: compact);
  }
}

enum _ProfileMenuAction { profile, settings, logout }

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = _resolvedUserName(authState, l.crmUser);
        final email = (authState.userProfile?.email ??
                authState.user?.email ??
                '')
            .trim();
        final photoUrl = _resolvedUserPhotoUrl(authState);
        final photoCacheKey = _resolvedUserPhotoCacheKey(authState);
        _debugProfileImageSources(authState, 'account menu avatar');

        return PopupMenuButton<_ProfileMenuAction>(
          tooltip: l.profile,
          position: PopupMenuPosition.under,
          offset: const Offset(0, AppSpacing.xs),
          color: colors.cardSurface,
          elevation: 10,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xLarge,
            side: BorderSide(color: colors.border),
          ),
          onSelected: (action) {
            switch (action) {
              case _ProfileMenuAction.profile:
                context.go(RouteNames.profile);
              case _ProfileMenuAction.settings:
                context.go(RouteNames.settings);
              case _ProfileMenuAction.logout:
                context.read<AuthBloc>().add(const AuthSignOutRequested());
            }
          },
          itemBuilder: (menuContext) {
            return [
              PopupMenuItem<_ProfileMenuAction>(
                enabled: false,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _ProfileMenuHeader(
                  name: userName,
                  subtitle: email,
                  photoUrl: photoUrl,
                  cacheKey: photoCacheKey,
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<_ProfileMenuAction>(
                value: _ProfileMenuAction.profile,
                child: _ProfileMenuTile(
                  icon: Icons.person_outline,
                  label: l.profile,
                ),
              ),
              PopupMenuItem<_ProfileMenuAction>(
                value: _ProfileMenuAction.settings,
                child: _ProfileMenuTile(
                  icon: Icons.settings_outlined,
                  label: l.settings,
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<_ProfileMenuAction>(
                value: _ProfileMenuAction.logout,
                child: _ProfileMenuTile(
                  icon: Icons.logout,
                  label: l.logout,
                  destructive: true,
                ),
              ),
            ];
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 0 : 2),
              child: _UserAvatar(
                name: userName,
                photoUrl: photoUrl,
                cacheKey: photoCacheKey,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuHeader extends StatelessWidget {
  const _ProfileMenuHeader({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.cacheKey,
  });

  final String name;
  final String subtitle;
  final String photoUrl;
  final String cacheKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(name: name, photoUrl: photoUrl, cacheKey: cacheKey),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.errorColor(context)
        : AppColors.textPrimaryColor(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
        ],
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.name, this.photoUrl, this.cacheKey});

  final String? name;
  final String? photoUrl;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    return MasarUserAvatar(
      name: name ?? AppLocalizations.of(context)!.crmUser,
      photoUrl: photoUrl ?? '',
      cacheKey: cacheKey ?? '',
      radius: 18,
    );
  }
}

String _resolvedUserPhotoUrl(AuthState state) {
  final profilePhoto = (state.userProfile?.photoUrl ?? '').trim();
  if (profilePhoto.isNotEmpty) {
    return profilePhoto;
  }
  return (state.user?.photoUrl ?? '').trim();
}

String _resolvedUserPhotoCacheKey(AuthState state) {
  final profile = state.userProfile;
  if (profile != null) {
    return [
      profile.photoStoragePath,
      profile.updatedAt.millisecondsSinceEpoch.toString(),
      profile.photoUrl.hashCode.toString(),
    ].where((part) => part.trim().isNotEmpty).join(':');
  }
  final user = state.user;
  if (user == null) {
    return '';
  }
  return '${user.uid}:${(user.photoUrl ?? '').hashCode}';
}

void _debugProfileImageSources(AuthState state, String source) {
  // Intentionally silent. Avoid noisy profile image logs and URL/token output.
  return;
}
String _resolvedUserName(AuthState state, String fallback) {
  final profileName = (state.userProfile?.fullName ?? '').trim();
  if (profileName.isNotEmpty) {
    return profileName;
  }

  final userName = (state.user?.fullName ?? '').trim();
  if (userName.isNotEmpty) {
    return userName;
  }

  return fallback;
}

class _CrmShellColors {
  const _CrmShellColors({
    required this.background,
    required this.chromeSurface,
    required this.cardSurface,
    required this.inputSurface,
    required this.selectedSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.error,
  });

  final Color background;
  final Color chromeSurface;
  final Color cardSurface;
  final Color inputSurface;
  final Color selectedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color error;

  factory _CrmShellColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isDark) {
      return const _CrmShellColors(
        background: AppColors.background,
        chromeSurface: AppColors.backgroundSoft,
        cardSurface: AppColors.surface,
        inputSurface: AppColors.backgroundHighlight,
        selectedSurface: AppColors.primaryLight,
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        primary: AppColors.primaryDeep,
        error: AppColors.error,
      );
    }

    return const _CrmShellColors(
      background: AppColors.darkBackground,
      chromeSurface: AppColors.darkSurface,
      cardSurface: AppColors.darkCardSurface,
      inputSurface: AppColors.darkSurfaceAlt,
      selectedSurface: AppColors.darkSelectedSurface,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      primary: AppColors.darkPrimary,
      error: AppColors.darkError,
    );
  }
}

class _CrmShellItem {
  const _CrmShellItem({
    required this.item,
    required this.icon,
    required this.selectedIcon,
  });

  final CrmNavigationItem item;
  final IconData icon;
  final IconData selectedIcon;

  String label(BuildContext context) => _labelFor(context, item);
}

String _labelFor(BuildContext context, CrmNavigationItem item) {
  final localizations = AppLocalizations.of(context)!;

  switch (item) {
    case CrmNavigationItem.dashboard:
      return localizations.dashboard;
    case CrmNavigationItem.leads:
      return localizations.leads;
    case CrmNavigationItem.properties:
      return localizations.properties;
    case CrmNavigationItem.clients:
      return localizations.clients;
    case CrmNavigationItem.tasks:
      return localizations.tasks;
    case CrmNavigationItem.appointments:
      return localizations.appointments;
    case CrmNavigationItem.deals:
      return localizations.deals;
    case CrmNavigationItem.reports:
      return localizations.reports;
    case CrmNavigationItem.auditLogs:
      return localizations.auditLogs;
    case CrmNavigationItem.users:
      return localizations.userManagement;
    case CrmNavigationItem.teams:
      return localizations.teamManagement;
    case CrmNavigationItem.dataHealth:
      return localizations.dataHealth;
    case CrmNavigationItem.support:
      return localizations.supportCenter;
    case CrmNavigationItem.more:
      return localizations.more;
  }
}
