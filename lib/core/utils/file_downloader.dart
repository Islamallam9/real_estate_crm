import 'dart:typed_data';

import 'downloaded_file_result.dart';
import 'file_downloader_stub.dart'
    if (dart.library.io) 'file_downloader_io.dart'
    if (dart.library.html) 'file_downloader_web.dart';

export 'downloaded_file_result.dart';

Future<DownloadedFileResult> downloadBytes({
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

Future<bool> openDownloadedFile(DownloadedFileResult file) {
  return openDownloadedFileImpl(file);
}

Future<bool> openDownloadsLocation([DownloadedFileResult? file]) {
  return openDownloadsLocationImpl(file);
}
