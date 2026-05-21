// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> openExternalLinkImpl(String url) async {
  final clean = url.trim();
  final uri = Uri.tryParse(clean);
  if (uri == null || !uri.hasScheme) {
    return false;
  }

  final scheme = uri.scheme.toLowerCase();
  final isWebUrl = scheme == 'http' || scheme == 'https';
  final isNativeUrl = scheme == 'mailto' || scheme == 'tel';
  if (!isWebUrl && !isNativeUrl) {
    return false;
  }
  if (isWebUrl && uri.host.isEmpty) {
    return false;
  }

  if (isNativeUrl) {
    html.window.location.href = clean;
  } else {
    html.window.open(clean, '_blank', 'noopener,noreferrer');
  }
  return true;
}
