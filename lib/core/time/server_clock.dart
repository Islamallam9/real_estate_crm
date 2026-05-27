import 'package:cloud_functions/cloud_functions.dart';

/// Server-authoritative clock for payment/trial UX.
///
/// The client never uses the device wall clock directly for trial remaining
/// time. We anchor to a Cloud Function server timestamp, then advance with a
/// monotonic Stopwatch so changing the laptop/phone date cannot fake remaining
/// time in the UI.
class ServerClock {
  ServerClock._({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  static final ServerClock instance = ServerClock._();

  final FirebaseFunctions _functions;
  DateTime? _serverAnchor;
  Stopwatch? _stopwatch;
  static const Duration _refreshAfter = Duration(minutes: 1);

  DateTime? get estimatedNow {
    final anchor = _serverAnchor;
    final watch = _stopwatch;
    if (anchor == null || watch == null) {
      return null;
    }
    return anchor.add(watch.elapsed);
  }

  Future<DateTime> now({bool forceRefresh = false}) async {
    final current = estimatedNow;
    final watch = _stopwatch;
    if (!forceRefresh && current != null && watch != null) {
      if (watch.elapsed < _refreshAfter) {
        return current;
      }
    }
    return refresh();
  }

  Future<DateTime> refresh() async {
    final callable = _functions.httpsCallable('getServerTime');
    final result = await callable.call<Map<String, dynamic>>();
    final data = result.data;
    final millis = data['nowMillis'];
    final iso = data['now'];

    final serverNow = millis is num
        ? DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true)
        : DateTime.parse(iso as String).toUtc();

    _serverAnchor = serverNow;
    _stopwatch = Stopwatch()..start();
    return serverNow;
  }
}
