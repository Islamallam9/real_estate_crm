import 'package:url_launcher/url_launcher.dart';

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

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
