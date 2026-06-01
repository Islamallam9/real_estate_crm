import 'dart:typed_data';

import 'downloaded_file_result.dart';

Future<DownloadedFileResult> downloadBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  return const DownloadedFileResult(success: false);
}

Future<bool> openDownloadedFileImpl(DownloadedFileResult file) async {
  return false;
}

Future<bool> openDownloadsLocationImpl([DownloadedFileResult? file]) async {
  return false;
}
