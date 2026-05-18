import 'package:equatable/equatable.dart';

import 'appointment.dart';

class AppointmentRelatedRecordOption extends Equatable {
  const AppointmentRelatedRecordOption({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final AppointmentRelatedType type;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => [id, type, title, subtitle];
}
