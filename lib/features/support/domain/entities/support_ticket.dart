import 'package:equatable/equatable.dart';

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.type,
    required this.category,
    required this.priority,
    required this.rating,
    required this.title,
    required this.message,
    required this.status,
    required this.appVersion,
    required this.appBuildNumber,
    required this.platform,
    required this.currentRoute,
    required this.deviceInfo,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
    required this.lastReplyAt,
    required this.lastReplyBy,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String type;
  final String category;
  final String priority;
  final int? rating;
  final String title;
  final String message;
  final String status;
  final String appVersion;
  final String appBuildNumber;
  final String platform;
  final String currentRoute;
  final String deviceInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? lastReplyAt;
  final String lastReplyBy;

  bool get isFeedback => type == SupportTicketType.feedback;

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        userId,
        userName,
        userEmail,
        userRole,
        type,
        category,
        priority,
        rating,
        title,
        message,
        status,
        appVersion,
        appBuildNumber,
        platform,
        currentRoute,
        deviceInfo,
        createdAt,
        updatedAt,
        resolvedAt,
        lastReplyAt,
        lastReplyBy,
      ];
}

abstract final class SupportTicketType {
  static const support = 'support';
  static const feedback = 'feedback';
}

abstract final class SupportTicketStatus {
  static const open = 'open';
  static const inReview = 'inReview';
  static const waitingForUser = 'waitingForUser';
  static const resolved = 'resolved';
  static const closed = 'closed';

  static const values = [
    open,
    inReview,
    waitingForUser,
    resolved,
    closed,
  ];
}

abstract final class SupportTicketPriority {
  static const low = 'low';
  static const normal = 'normal';
  static const urgent = 'urgent';

  static const values = [low, normal, urgent];
}

abstract final class SupportCategory {
  static const accountLogin = 'accountLogin';
  static const usersPermissions = 'usersPermissions';
  static const leads = 'leads';
  static const clients = 'clients';
  static const properties = 'properties';
  static const tasks = 'tasks';
  static const deals = 'deals';
  static const notifications = 'notifications';
  static const appointments = 'appointments';
  static const billingSubscription = 'billingSubscription';
  static const bug = 'bug';
  static const other = 'other';

  static const values = [
    accountLogin,
    usersPermissions,
    leads,
    clients,
    properties,
    tasks,
    deals,
    notifications,
    appointments,
    billingSubscription,
    bug,
    other,
  ];
}

abstract final class FeedbackCategory {
  static const suggestion = 'suggestion';
  static const uiImprovement = 'uiImprovement';
  static const missingFeature = 'missingFeature';
  static const confusingBehavior = 'confusingBehavior';
  static const performance = 'performance';
  static const generalFeedback = 'generalFeedback';

  static const values = [
    suggestion,
    uiImprovement,
    missingFeature,
    confusingBehavior,
    performance,
    generalFeedback,
  ];
}
