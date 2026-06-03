import 'package:equatable/equatable.dart';

enum NotificationPushTokenScopeKind { none, company, platformOwner }

enum NotificationPushTokenStatus {
  idle,
  ready,
  syncing,
  registered,
  permissionRequired,
  denied,
  unavailable,
  failed,
}

enum NotificationPushTokenPromptAction { none, notNow, dismissed, retryLater }

class NotificationPushTokenState extends Equatable {
  const NotificationPushTokenState({
    this.scope = NotificationPushTokenScopeKind.none,
    this.companyId = '',
    this.uid = '',
    this.role = '',
    this.locale = 'en',
    this.token = '',
    this.isSyncing = false,
    this.status = NotificationPushTokenStatus.idle,
    this.lastError = '',
    this.promptDismissedUntil,
    this.localRegistrationHint = false,
  });

  final NotificationPushTokenScopeKind scope;
  final String companyId;
  final String uid;
  final String role;
  final String locale;
  final String token;
  final bool isSyncing;
  final NotificationPushTokenStatus status;
  final String lastError;
  final DateTime? promptDismissedUntil;
  final bool localRegistrationHint;

  bool get hasSession => uid.trim().isNotEmpty && scope != NotificationPushTokenScopeKind.none;

  bool get isRegistered =>
      token.trim().isNotEmpty &&
      status == NotificationPushTokenStatus.registered &&
      !hasConfigurationError;

  bool get isPromptSnoozed {
    final until = promptDismissedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  bool get hasConfigurationError => lastError == 'missing-web-vapid-key';

  bool get needsUserAction =>
      hasSession &&
      !isRegistered &&
      status != NotificationPushTokenStatus.idle &&
      status != NotificationPushTokenStatus.ready &&
      status != NotificationPushTokenStatus.syncing;

  bool get canShowPromptBanner =>
      hasSession &&
      status == NotificationPushTokenStatus.permissionRequired &&
      !isRegistered &&
      !isPromptSnoozed &&
      !hasConfigurationError;

  bool get canShowManualControl => hasSession;

  bool get shouldShowAsConnected => isRegistered;

  bool get shouldAutoSync =>
      hasSession &&
      !isRegistered &&
      status != NotificationPushTokenStatus.syncing &&
      status != NotificationPushTokenStatus.denied;

  NotificationPushTokenState copyWith({
    NotificationPushTokenScopeKind? scope,
    String? companyId,
    String? uid,
    String? role,
    String? locale,
    String? token,
    bool? isSyncing,
    NotificationPushTokenStatus? status,
    String? lastError,
    DateTime? promptDismissedUntil,
    bool clearPromptDismissedUntil = false,
    bool? localRegistrationHint,
  }) {
    return NotificationPushTokenState(
      scope: scope ?? this.scope,
      companyId: companyId ?? this.companyId,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      locale: locale ?? this.locale,
      token: token ?? this.token,
      isSyncing: isSyncing ?? this.isSyncing,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      promptDismissedUntil: clearPromptDismissedUntil
          ? null
          : (promptDismissedUntil ?? this.promptDismissedUntil),
      localRegistrationHint: localRegistrationHint ?? this.localRegistrationHint,
    );
  }

  @override
  List<Object?> get props => [
        scope,
        companyId,
        uid,
        role,
        locale,
        token,
        isSyncing,
        status,
        lastError,
        promptDismissedUntil,
        localRegistrationHint,
      ];
}
