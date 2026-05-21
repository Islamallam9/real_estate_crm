import 'dart:async';

class InitialLoadTimeout {
  InitialLoadTimeout({
    this.duration = const Duration(seconds: 30),
  });

  final Duration duration;
  Timer? _timer;

  void start(void Function() onTimeout) {
    cancel();
    _timer = Timer(duration, onTimeout);
  }

  void complete() {
    cancel();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
