import 'package:equatable/equatable.dart';

class CompanyMetadata extends Equatable {
  const CompanyMetadata({
    required this.id,
    required this.name,
    required this.displayName,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.settings,
    required this.limits,
    required this.features,
  });

  final String id;
  final String name;
  final String displayName;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final Map<String, Object?> settings;
  final Map<String, Object?> limits;
  final Map<String, Object?> features;

  bool get isUsable => isActive && status == 'active';

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    status,
    isActive,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    settings,
    limits,
    features,
  ];
}
