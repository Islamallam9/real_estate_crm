import 'dart:html' as html;
import 'dart:typed_data';

import 'downloaded_file_result.dart';

Future<DownloadedFileResult> downloadBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return DownloadedFileResult(
    success: true,
    fileName: fileName,
    displayPath: fileName,
    mimeType: mimeType,
  );
}

Future<bool> openDownloadedFileImpl(DownloadedFileResult file) async {
  return false;
}

Future<bool> openDownloadsLocationImpl([DownloadedFileResult? file]) async {
  return false;
}
