import 'dart:async';
import 'package:flutter/foundation.dart';

class Throttler {
  final Duration _duration;
  Timer? _timer;

  Throttler({required Duration duration}) : _duration = duration;

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) return;

    _timer = Timer(_duration, () {});
    action();
  }
}

class Debouncer {
  final Duration _duration;
  Timer? _timer;

  Debouncer({required Duration duration}) : _duration = duration;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_duration, action);
  }
}
