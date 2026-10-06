import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/music_loader_native.dart' if (dart.library.html) 'package:mafia_engine/data/music_loader_web.dart' as music_loader;

enum MusicPlaylist {
  invalid,
  preparation,
  lowIntensity,
  mediumIntensity,
  highIntensity,
  special,
}

class MusicTrack {
  final String title;
  final String path;
  final MusicPlaylist playlist;

  Duration? skipLeading;
  Duration? skipTrailing;
  double? volumeAdjustment;

  MusicTrack({
    required this.path,
    required this.title,
    required this.playlist,
    this.skipLeading,
    this.skipTrailing,
    this.volumeAdjustment,
  });
}

class MusicProgressNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class MusicService {
  bool get isAvailable => !kIsWeb;
  bool get hasPlayback => _currentTrack != null;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  MusicTrack? get currentTrack => _currentTrack;
  String? get currentTrackTitle => _currentTrack?.title;
  num? get currentTrackDuration => _currentPlayer?.duration?.inSeconds;
  num? get currentTrackPosition => _currentPlayer?.position.inSeconds;
  MusicPlaylist? get currentPlaylist => _currentTrack?.playlist;

  MusicTrack? _currentTrack;
  AudioPlayer? _currentPlayer;
  AudioPlayer? _crossfadePlayer;

  final List<Timer> _currentFadeTimers = [];
  final Map<MusicPlaylist, List<MusicTrack>> _musicTracks = {};
  final Map<MusicTrack, int> _playCounts = {};
  final Random _random = Random();
  final MusicProgressNotifier progressNotifier = MusicProgressNotifier();
  final GameConfigService _configService;
  final FileSystemService _fileSystemService;

  MusicService(this._configService, this._fileSystemService) {
    if (isAvailable) _loadPlaylists();
  }

  void _loadPlaylists() async {
    _musicTracks.addAll(await music_loader.loadPlaylists(_fileSystemService));
  }

  void _instantiatePlayersIfNeeded() {
    _currentPlayer ??= _instantiatePlayer();
    _crossfadePlayer ??= _instantiatePlayer();
  }

  AudioPlayer _instantiatePlayer() {
    final player = AudioPlayer();
    player.playbackEventStream.listen((event) {
      switch (event.processingState) {
        case ProcessingState.loading:
        case ProcessingState.buffering:
        case ProcessingState.ready:
          break;
        case ProcessingState.idle:
          break;

        case ProcessingState.completed:
          break;
      }

      progressNotifier.notify();
    });

    player.positionStream.listen((progress) {
      progressNotifier.notify();
      if (player != _currentPlayer) return;
      if (_currentTrack == null) return;

      final duration = player.duration?.inSeconds.toInt() ?? 0;
      if (duration == 0) return;

      progress -= _endingPositionAdjustmentForTrack(_currentTrack);
      if (duration - progress.inSeconds <=
          _configService.musicCrossfadeDuration.inSeconds) {
        _startNextSongCrossfade(_currentTrack!);
      }
    });

    return player;
  }

  MusicPlaylist findNonEmptyPlaylist(MusicPlaylist targetName) {
    final targetIndex = MusicPlaylist.values.indexOf(targetName);
    var index = targetIndex;
    while (true) {
      final name = MusicPlaylist.values[index];
      if (_musicTracks[name]?.isNotEmpty == true) {
        return name;
      }

      index++;
      if (index >= MusicPlaylist.values.length) {
        index = 0;
      }

      if (index == targetIndex) break;
    }

    return MusicPlaylist.invalid;
  }

  bool checkPlaylistHaveSongs(MusicPlaylist name) {
    return _musicTracks[name]?.isNotEmpty == true;
  }

  Iterable<MusicTrack> iterateTracksInPlaylist(MusicPlaylist name) {
    final playlist = _musicTracks[name];
    if (playlist != null) return playlist;
    return [];
  }

  void resetPlayCounts() => _playCounts.clear();

  void startTrackWithFadeIn(MusicTrack track) {
    _startTrackFadeIn(track);
  }

  void startWithFadeInFromPlaylist(MusicPlaylist playlistName) {
    final playlist = _musicTracks[playlistName];
    if (playlist?.isNotEmpty != true) {
      _currentTrack = null;
      return;
    }

    final track = _selectLeastPlayedSongFromPlaylist(playlistName);
    if (track != null) startTrackWithFadeIn(track);
  }

  void skipWithFadeInFromPlaylist(MusicPlaylist playlistName) {
    MusicTrack? track;

    if (_currentTrack != null && _currentTrack!.playlist == playlistName) {
      track = _selectDifferentSongFromPlaylist(_currentTrack!);
    } else {
      track = _selectLeastPlayedSongFromPlaylist(playlistName);
    }
    if (track == null) return;
    startTrackWithFadeIn(track);
  }

  void skipWithCrossfade() {
    if (_currentTrack != null) {
      _startNextSongCrossfade(_currentTrack!);
    }
  }

  void stopWithFadeOut() {
    _currentTrack = null;
    _stopVolumeFades();
    _startVolumeFade(
      _currentPlayer!,
      _currentPlayer!.volume,
      0.0,
      _configService.musicFadeOutDuration,
    );
    _startVolumeFade(
      _crossfadePlayer!,
      _crossfadePlayer!.volume,
      0.0,
      _configService.musicFadeOutDuration,
    );
    progressNotifier.notify();
  }

  void togglePause() {
    if (!_isPaused) {
      _currentPlayer?.pause();
      _isPaused = true;
    } else {
      _currentPlayer?.play();
      _isPaused = false;
    }
    progressNotifier.notify();
  }

  void fastForward() {
    var currentPosition = _currentPlayer?.position;
    if (currentPosition == null) return;
    currentPosition += Duration(seconds: 5);
    _currentPlayer!.seek(currentPosition);
    progressNotifier.notify();
  }

  Future _startTrackFadeIn(MusicTrack track) async {
    _currentTrack = track;
    _playCounts.update(track, (count) => count + 1, ifAbsent: () => 1);
    _instantiatePlayersIfNeeded();
    await _currentPlayer!.setFilePath(_currentTrack!.path);

    _stopVolumeFades();
    _startVolumeFade(
      _currentPlayer!,
      0.0,
      _volumeForTrack(_currentTrack!),
      _configService.musicFadeInDuration,
    );
    _crossfadePlayer!.stop();
    await _currentPlayer!.load();
    _currentPlayer!.play();
    _currentPlayer!.seek(_startingPositionForTrack(_currentTrack!));
    progressNotifier.notify();
  }

  Future _startNextSongCrossfade(MusicTrack lastTrack) async {
    _currentTrack = _selectDifferentSongFromPlaylist(lastTrack);
    if (_currentTrack == null) return;
    _playCounts.update(_currentTrack!, (count) => count + 1, ifAbsent: () => 1);

    _instantiatePlayersIfNeeded();
    final oldCrossfadePlayer = _crossfadePlayer;
    _crossfadePlayer = _currentPlayer;
    _currentPlayer = oldCrossfadePlayer;

    _stopVolumeFades();
    _startVolumeFade(
      _crossfadePlayer!,
      _crossfadePlayer!.volume,
      0.0,
      _configService.musicCrossfadeDuration,
    );

    await _currentPlayer!.setFilePath(_currentTrack!.path);
    _startVolumeFade(
      _currentPlayer!,
      0.0,
      _volumeForTrack(_currentTrack!),
      Duration(
        milliseconds: (_configService.musicCrossfadeDuration.inMilliseconds / 2)
            .toInt(),
      ),
    );
    await _currentPlayer!.load();
    _currentPlayer!.play();
    _currentPlayer!.seek(_startingPositionForTrack(_currentTrack!));
    progressNotifier.notify();
  }

  double _volumeForTrack(MusicTrack track) {
    return _configService.musicVolume * (track.volumeAdjustment ?? 1);
  }

  Duration _startingPositionForTrack(MusicTrack track) {
    return track.skipLeading ?? Duration.zero;
  }

  Duration _endingPositionAdjustmentForTrack(MusicTrack? track) {
    return -(track?.skipTrailing ?? Duration.zero);
  }

  MusicTrack? _selectDifferentSongFromPlaylist(MusicTrack lastTrack) {
    return _selectLeastPlayedSongFromPlaylist(lastTrack.playlist, lastTrack);
  }

  MusicTrack? _selectLeastPlayedSongFromPlaylist(
    MusicPlaylist playlistName, [
    MusicTrack? lastTrack,
  ]) {
    final playlist = _musicTracks[playlistName];
    if (playlist?.isNotEmpty != true) return null;

    final leastPlayed = playlist!
        .map((track) => _playCounts[track] ?? 0)
        .reduce((a, b) => a < b ? a : b);
    final candidates = playlist
        .where((track) => (_playCounts[track] ?? 0) == leastPlayed)
        .toList();
    if (candidates.length > 1) candidates.remove(lastTrack);
    return candidates[_random.nextInt(candidates.length)];
  }

  void _startVolumeFade(
    AudioPlayer player,
    double from,
    double to,
    Duration duration,
  ) {
    player.setVolume(from);

    var steps = (duration.inMilliseconds / 100).ceil();
    final stepDelta = (to - from) / steps;
    _currentFadeTimers.add(
      Timer.periodic(Duration(milliseconds: 100), (timer) async {
        var volume = player.volume;
        volume += stepDelta;
        await player.setVolume(volume);
        steps--;

        if (steps < 0) {
          if (volume <= 0) {
            await player.stop();
          }
          timer.cancel();
          _currentFadeTimers.remove(timer);
        }
      }),
    );
  }

  void _stopVolumeFades() {
    for (final timer in _currentFadeTimers) {
      timer.cancel();
    }
  }
}
