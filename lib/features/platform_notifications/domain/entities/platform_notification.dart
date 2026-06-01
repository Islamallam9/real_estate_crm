import 'package:equatable/equatable.dart';

enum PlatformNotificationSeverity { info, success, warning, urgent }

enum PlatformNotificationDeliveryMode { inAppOnly, pushEligible, attentionOnly, auditOnly }

enum PlatformNotificationRecipientScope { user, managerTeam, admins, platformOwner }

enum PlatformNotificationSource {
  platform,
  support,
  invitation,
  company,
  user,
  storage,
  system,
}

enum PlatformNotificationType {
  companyRegistered,
  companyCreated,
  companyStatusChanged,
  companySettingsChanged,
  companyFeatureChanged,
  companyLimitChanged,
  companyUserCreated,
  companyUserStatusChanged,
  companyUserPasswordReset,
  dealWon,
  dealLost,
  invitationCreated,
  invitationAccepted,
  invitationRevoked,
  supportTicketCreated,
  feedbackSubmitted,
  urgentSupportTicketCreated,
  supportTicketStatusChanged,
  storageUsageRefreshed,
  storageNearLimit,
  platformFunctionFailed,
  trialEndingSoon,
  trialExpired,
  paymentDueSoon,
  paymentOverdue,
  paymentGraceEnding,
  paymentSuspended,
  paymentReactivated,
  paymentMarkedPaid,
  unknown,
}

class PlatformNotification extends Equatable {
  const PlatformNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.deliveryMode,
    required this.recipientScope,
    required this.dedupeKey,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.readAt,
    required this.actorId,
    required this.actorName,
    required this.actorEmail,
    required this.companyId,
    required this.companyName,
    required this.route,
    required this.metadata,
    required this.source,
  });

  final String id;
  final PlatformNotificationType type;
  final String title;
  final String message;
  final PlatformNotificationSeverity severity;
  final PlatformNotificationDeliveryMode deliveryMode;
  final PlatformNotificationRecipientScope recipientScope;
  final String dedupeKey;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final String actorId;
  final String actorName;
  final String actorEmail;
  final String companyId;
  final String companyName;
  final String route;
  final Map<String, Object?> metadata;
  final PlatformNotificationSource source;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        severity,
        deliveryMode,
        recipientScope,
        dedupeKey,
        isRead,
        createdAt,
        updatedAt,
        readAt,
        actorId,
        actorName,
        actorEmail,
        companyId,
        companyName,
        route,
        metadata,
        source,
      ];
}

PlatformNotificationType platformNotificationTypeFromValue(String value) {
  return PlatformNotificationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => PlatformNotificationType.unknown,
  );
}

PlatformNotificationSeverity platformNotificationSeverityFromValue(
  String value,
) {
  return PlatformNotificationSeverity.values.firstWhere(
    (severity) => severity.name == value,
    orElse: () => PlatformNotificationSeverity.info,
  );
}

PlatformNotificationDeliveryMode platformNotificationDeliveryModeFromValue(
  String value,
) {
  return PlatformNotificationDeliveryMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => PlatformNotificationDeliveryMode.inAppOnly,
  );
}

PlatformNotificationRecipientScope platformNotificationRecipientScopeFromValue(
  String value,
) {
  return PlatformNotificationRecipientScope.values.firstWhere(
    (scope) => scope.name == value,
    orElse: () => PlatformNotificationRecipientScope.platformOwner,
  );
}

PlatformNotificationSource platformNotificationSourceFromValue(String value) {
  return PlatformNotificationSource.values.firstWhere(
    (source) => source.name == value,
    orElse: () => PlatformNotificationSource.platform,
  );
}
