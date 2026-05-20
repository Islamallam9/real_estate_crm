import 'package:equatable/equatable.dart';

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    required this.isPlatformReply,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime? createdAt;
  final bool isPlatformReply;

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderRole,
        message,
        createdAt,
        isPlatformReply,
      ];
}
