// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none'
      ..click();
    return true;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
