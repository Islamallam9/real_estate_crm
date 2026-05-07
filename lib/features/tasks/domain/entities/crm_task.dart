import 'package:equatable/equatable.dart';

enum TaskRelatedType { lead, client, property, deal, general }

enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { low, medium, high }

class CrmTask extends Equatable {
  const CrmTask({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.relatedType,
    required this.relatedId,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.isActive,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String assignedTo;
  final TaskRelatedType relatedType;
  final String relatedId;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    companyId,
    title,
    description,
    assignedTo,
    relatedType,
    relatedId,
    dueDate,
    status,
    priority,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    isActive,
  ];
}
