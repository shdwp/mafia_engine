import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mafia_engine/data/game_config.dart';

class GameTimerNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

const _timerSoundAssets = {
  10: 'assets/5.mp3',
  4: 'assets/4.mp3',
  3: 'assets/3.mp3',
  2: 'assets/2.mp3',
  1: 'assets/1.mp3',
};

class GameTimer {
  int? _remainingSeconds;
  bool _paused = false;
  bool _playSounds = true;

  final GameConfigService _configService;
  final Map<int, AudioPlayer> _soundPlayers = {};

  GameTimerNotifier notifier = GameTimerNotifier();

  bool get soundsEnabled => _playSounds;

  GameTimer(this._configService) {
    _preloadSounds();
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds != null && _remainingSeconds! > 0 && !_paused) {
        _remainingSeconds = max(0, _remainingSeconds! - 1);
        if (_playSounds) _playTimerSound(_remainingSeconds!);
        notifier.notify();
      }
    });
  }

  void _preloadSounds() async {
    for (final entry in _timerSoundAssets.entries) {
      final player = AudioPlayer();
      await player.setAsset(entry.value);
      _soundPlayers[entry.key] = player;
    }
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

  void start(int seconds, {bool playSounds = true}) {
    _remainingSeconds = seconds;
    _paused = false;
    _playSounds = playSounds;
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

  void toggleSounds() {
    _playSounds = !_playSounds;
    notifier.notify();
  }

  void setSoundsEnabled(bool enabled) {
    _playSounds = enabled;
    notifier.notify();
  }

  void _playTimerSound(int remaining) {
    final player = _soundPlayers[remaining];
    if (player == null) return;

    if (_configService.timerSoundVolume > 0) {
      player.setVolume(_configService.timerSoundVolume);
      player.seek(Duration.zero).then((_) => player.play());
    }
  }
}
