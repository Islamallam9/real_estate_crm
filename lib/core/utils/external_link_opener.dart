import 'external_link_opener_stub.dart'
    if (dart.library.io) 'external_link_opener_io.dart'
    if (dart.library.html) 'external_link_opener_web.dart';

Future<bool> openExternalLink(String url) => openExternalLinkImpl(url);
