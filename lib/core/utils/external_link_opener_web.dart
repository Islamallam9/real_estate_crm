// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> openExternalLinkImpl(String url) async {
  final clean = url.trim();
  final uri = Uri.tryParse(clean);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return false;
  }
  html.window.open(clean, '_blank', 'noopener,noreferrer');
  return true;
}
