import 'package:equatable/equatable.dart';

class LeadNote extends Equatable {
  const LeadNote({
    required this.id,
    required this.leadId,
    required this.companyId,
    required this.text,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String leadId;
  final String companyId;
  final String text;
  final DateTime createdAt;
  final String createdBy;

  @override
  List<Object?> get props => [
    id,
    leadId,
    companyId,
    text,
    createdAt,
    createdBy,
  ];
}
