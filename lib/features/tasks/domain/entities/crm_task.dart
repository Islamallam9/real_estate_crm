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
    required this.relatedTitle,
    required this.relatedSubtitle,
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
  final String relatedTitle;
  final String relatedSubtitle;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isActive;

  CrmTask copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? assignedTo,
    TaskRelatedType? relatedType,
    String? relatedId,
    String? relatedTitle,
    String? relatedSubtitle,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isActive,
  }) {
    return CrmTask(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      relatedTitle: relatedTitle ?? this.relatedTitle,
      relatedSubtitle: relatedSubtitle ?? this.relatedSubtitle,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    title,
    description,
    assignedTo,
    relatedType,
    relatedId,
    relatedTitle,
    relatedSubtitle,
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
