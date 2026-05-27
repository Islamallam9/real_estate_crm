import 'package:equatable/equatable.dart';

class ExportColumn extends Equatable {
  const ExportColumn({
    required this.id,
    required this.label,
    this.recommended = true,
  });

  final String id;
  final String label;
  final bool recommended;

  @override
  List<Object?> get props => [id, label, recommended];
}
