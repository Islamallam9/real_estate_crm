import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class PropertyImageUpload extends Equatable {
  const PropertyImageUpload({
    required this.fileName,
    required this.bytes,
    required this.contentType,
  });

  final String fileName;
  final Uint8List bytes;
  final String contentType;

  @override
  List<Object?> get props => [fileName, bytes, contentType];
}
