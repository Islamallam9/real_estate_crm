import 'package:equatable/equatable.dart';

class ExportAssignee extends Equatable {
  const ExportAssignee({
    required this.uid,
    required this.name,
    required this.email,
  });

  final String uid;
  final String name;
  final String email;

  String get displayName => name.trim().isEmpty ? email : name;

  @override
  List<Object?> get props => [uid, name, email];
}
