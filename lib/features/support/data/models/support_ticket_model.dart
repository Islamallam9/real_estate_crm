import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/support_ticket.dart';

class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.userId,
    required super.userName,
    required super.userEmail,
    required super.userRole,
    required super.type,
    required super.category,
    required super.priority,
    required super.rating,
    required super.title,
    required super.message,
    required super.status,
    required super.appVersion,
    required super.appBuildNumber,
    required super.platform,
    required super.currentRoute,
    required super.deviceInfo,
    required super.createdAt,
    required super.updatedAt,
    required super.resolvedAt,
    required super.lastReplyAt,
    required super.lastReplyBy,
  });

  factory SupportTicketModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Support ticket data was not found.');
    }

    return SupportTicketModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userRole: data['userRole'] as String? ?? '',
      type: data['type'] as String? ?? SupportTicketType.support,
      category: data['category'] as String? ?? '',
      priority: data['priority'] as String? ?? SupportTicketPriority.normal,
      rating: _intFromValue(data['rating']),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? SupportTicketStatus.open,
      appVersion: data['appVersion'] as String? ?? '',
      appBuildNumber: data['appBuildNumber'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      currentRoute: data['currentRoute'] as String? ?? '',
      deviceInfo: data['deviceInfo'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      resolvedAt: _dateTimeFromValue(data['resolvedAt']),
      lastReplyAt: _dateTimeFromValue(data['lastReplyAt']),
      lastReplyBy: data['lastReplyBy'] as String? ?? '',
    );
  }
}

int? _intFromValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
