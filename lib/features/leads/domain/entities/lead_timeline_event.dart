import 'package:equatable/equatable.dart';

class LeadTimelineEvent extends Equatable {
  const LeadTimelineEvent({
    required this.id,
    required this.leadId,
    required this.companyId,
    required this.type,
    required this.title,
    required this.description,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.metadata,
  });

  final String id;
  final String leadId;
  final String companyId;
  final String type;
  final String title;
  final String description;
  final String oldValue;
  final String newValue;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
    id,
    leadId,
    companyId,
    type,
    title,
    description,
    oldValue,
    newValue,
    createdAt,
    createdBy,
    createdByName,
    metadata,
  ];
}
