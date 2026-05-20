import 'support_ticket.dart';

class SupportTicketDraft {
  const SupportTicketDraft({
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.type,
    required this.category,
    required this.priority,
    required this.title,
    required this.message,
    required this.appVersion,
    required this.appBuildNumber,
    required this.platform,
    required this.currentRoute,
    required this.deviceInfo,
    this.rating,
  });

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
  final String appVersion;
  final String appBuildNumber;
  final String platform;
  final String currentRoute;
  final String deviceInfo;

  bool get isFeedback => type == SupportTicketType.feedback;
}
