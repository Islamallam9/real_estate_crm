import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/support_message.dart';

class SupportMessageModel extends SupportMessage {
  const SupportMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.senderRole,
    required super.message,
    required super.createdAt,
    required super.isPlatformReply,
  });

  factory SupportMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Support message data was not found.');
    }
    return SupportMessageModel(
      id: data['id'] as String? ?? document.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      isPlatformReply: data['isPlatformReply'] as bool? ?? false,
    );
  }
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
