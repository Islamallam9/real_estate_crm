import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

Future<bool> downloadBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) {
  return downloadBytesImpl(
    fileName: fileName,
    mimeType: mimeType,
    bytes: bytes,
  );
}
