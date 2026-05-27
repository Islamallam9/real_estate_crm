import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ExportResult extends Equatable {
  const ExportResult({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.generatedAt,
    required this.recordCount,
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final DateTime generatedAt;
  final int recordCount;

  @override
  List<Object?> get props => [
    fileName,
    bytes.length,
    mimeType,
    generatedAt,
    recordCount,
  ];
}
