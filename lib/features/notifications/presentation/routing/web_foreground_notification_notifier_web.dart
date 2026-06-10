import 'dart:async';
import 'dart:html' as html;

String _cleanRoute(String route) {
  final trimmed = route.trim();
  if (trimmed.isEmpty ||
      trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('javascript:')) {
    return '/notifications';
  }
  if (trimmed.startsWith('/#')) {
    final hashIndex = trimmed.indexOf('#');
    final hashRoute = hashIndex >= 0 ? trimmed.substring(hashIndex + 1).trim() : '';
    return hashRoute.startsWith('/') ? hashRoute : '/notifications';
  }
  if (trimmed.startsWith('#/')) {
    return trimmed.substring(1);
  }
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}


final Map<String, DateTime> _recentBrowserNotificationTags = <String, DateTime>{};

bool _shouldSuppressRecentBrowserNotification(String tag) {
  final now = DateTime.now();
  _recentBrowserNotificationTags.removeWhere(
    (_, shownAt) => now.difference(shownAt) > const Duration(seconds: 45),
  );
  final previous = _recentBrowserNotificationTags[tag];
  if (previous != null && now.difference(previous) < const Duration(seconds: 12)) {
    return true;
  }
  _recentBrowserNotificationTags[tag] = now;
  return false;
}

String _hashForRoute(String route) => '#${_cleanRoute(route)}';

String _absoluteUrlForRoute(String route) {
  final cleanRoute = _cleanRoute(route);
  return '${html.window.location.origin}/#$cleanRoute';
}

String _absoluteAssetUrl(String path) {
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return '${html.window.location.origin}$cleanPath';
}

void navigateMasarWebRoute(String route) {
  final hash = _hashForRoute(route);
  if (html.window.location.hash == hash) {
    html.window.dispatchEvent(html.HashChangeEvent('hashchange'));
  } else {
    html.window.location.hash = hash;
  }
}

Future<void> showMasarWebForegroundNotification({
  required String title,
  required String body,
  required String route,
  required String tag,
}) async {
  if (!html.Notification.supported || html.Notification.permission != 'granted') {
    return;
  }

  final cleanTitle = title.trim().isEmpty ? 'Masar CRM' : title.trim();
  final cleanBody = body.trim().isEmpty
      ? 'Open Masar CRM to review the latest update.'
      : body.trim();
  final cleanRoute = _cleanRoute(route);
  final safeTag = tag.trim().isEmpty ? cleanRoute : tag.trim();
  if (_shouldSuppressRecentBrowserNotification(safeTag)) {
    return;
  }

  try {
    final browserNotification = html.Notification(
      cleanTitle,
      body: cleanBody,
      icon: _absoluteAssetUrl('/icons/Icon-192.png'),
      tag: safeTag,
    );
    browserNotification.onClick.listen((_) {
      try {
        browserNotification.close();
      } catch (_) {}
      navigateMasarWebRoute(cleanRoute);
    });
  } catch (_) {
    // Foreground notification display is best-effort.
  }
}

StreamSubscription<Object?>? listenForMasarWebNotificationClicks(
  void Function(String route) onRoute,
) {
  return html.window.onMessage.map<Object?>((event) => event).listen((rawEvent) {
    if (rawEvent is! html.MessageEvent) return;
    final data = rawEvent.data;
    final type = _readString(data, 'type');
    if (type != 'MASAR_FCM_NOTIFICATION_CLICK') return;
    final route = _readString(data, 'route');
    onRoute(_cleanRoute(route));
  });
}

String _readString(Object? data, String key) {
  if (data == null) return '';
  if (data is Map) {
    return data[key]?.toString().trim() ?? '';
  }
  return '';
}
