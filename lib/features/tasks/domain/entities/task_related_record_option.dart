import 'package:equatable/equatable.dart';

import 'crm_task.dart';

class TaskRelatedRecordOption extends Equatable {
  const TaskRelatedRecordOption({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final TaskRelatedType type;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => [id, type, title, subtitle];
}
