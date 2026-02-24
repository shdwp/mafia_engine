import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GameTimerNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class GameTimer {
  int? _remainingSeconds;
  bool _paused = false;

  GameTimerNotifier notifier = GameTimerNotifier();

  GameTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds != null && _remainingSeconds! > 0 && !_paused) {
        _remainingSeconds = max(0, _remainingSeconds! - 1);
        notifier.notify();
      }
    });
  }

  bool get hasTimer => (_remainingSeconds ?? 0) > 0;
  bool get isPaused => _paused;
  int get remainingSeconds => _remainingSeconds ?? 0;
  String get formattedTime {
    if (_remainingSeconds == null) return "--:--";
    if (_remainingSeconds! <= 0) return "00:00";

    int minutes = (_remainingSeconds! / 60).floor();
    int seconds = _remainingSeconds! - minutes * 60;

    final numberFormat = NumberFormat("00");
    return "${numberFormat.format(minutes)}:${numberFormat.format(seconds)}";
  }

  void start(int seconds) {
    _remainingSeconds = seconds;
    _paused = false;
    notifier.notify();
  }

  void stop() {
    _remainingSeconds = null;
    _paused = false;
    notifier.notify();
  }

  void togglePause() {
    _paused = !_paused;
    notifier.notify();
  }
}
