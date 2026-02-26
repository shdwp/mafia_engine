import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';

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
  final MusicProgressNotifier progressNotifier = MusicProgressNotifier();
  final GameConfigService _configService;
  final FileSystemService _fileSystemService;

  MusicService(this._configService, this._fileSystemService) {
    _loadPlaylists();
  }

  void _loadPlaylists() async {
    final dir = await _fileSystemService.openMusicDirectory();
    if (!await dir.exists()) return;

    final operatorExp = RegExp(r"[\.]?(\$([a-z]+)(\d+))[\.]?");
    final extensionExp = RegExp(r"(\.mp3|ogg|wav|mp4)$");

    final nameMap = MusicPlaylist.values.asNameMap();
    await for (final folderEntity in dir.list()) {
      if (folderEntity is Directory) {
        final playlistName = folderEntity
            .uri
            .pathSegments[folderEntity.uri.pathSegments.length - 2];

        final playlist = nameMap[playlistName];
        if (playlist == null) {
          continue;
        }

        if (!_musicTracks.containsKey(playlist)) _musicTracks[playlist] = [];
        await for (final fileEntity in folderEntity.list()) {
          if (fileEntity is! File) continue;
          final fileName = fileEntity.uri.pathSegments.last;
          final extensionMatch = extensionExp.firstMatch(fileName);
          if (extensionMatch == null) continue;

          var title = fileName.replaceFirst(extensionMatch.group(0)!, "");
          double? volumeAdjustment;
          Duration? leadingSkip;
          Duration? trailingSkip;

          for (final match in operatorExp.allMatches(fileName)) {
            final argument = int.tryParse(match.group(3) ?? "");
            if (argument == null) continue;

            title = title.replaceFirst(".${match.group(1)!}", "");
            title = title.replaceFirst(".${match.group(1)!}.", "");
            title = title.replaceFirst(match.group(1)!, "");
            switch (match.group(2)) {
              case "l":
                leadingSkip = Duration(seconds: argument);
                break;
              case "t":
                trailingSkip = Duration(seconds: argument);
                break;
              case "v":
                volumeAdjustment = argument / 100;
                break;
              default:
                break;
            }
          }

          _musicTracks[playlist]!.add(
            MusicTrack(
              path: fileEntity.path,
              title: title,
              playlist: nameMap[playlistName]!,
              skipLeading: leadingSkip,
              skipTrailing: trailingSkip,
              volumeAdjustment: volumeAdjustment,
            ),
          );
        }
      }
    }
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

  void startTrackWithFadeIn(MusicTrack track) {
    _startTrackFadeIn(track);
  }

  void startWithFadeInFromPlaylist(MusicPlaylist playlistName) {
    final playlist = _musicTracks[playlistName];
    if (playlist?.isNotEmpty != true) {
      _currentTrack = null;
      return;
    }

    startTrackWithFadeIn(playlist![Random().nextInt(playlist.length)]);
  }

  void skipWithFadeInFromPlaylist(MusicPlaylist playlistName) {
    MusicTrack? track;

    if (_currentTrack != null && _currentTrack!.playlist == playlistName) {
      track = _selectDifferentSongFromPlaylist(_currentTrack!);
    } else {
      track = _selectRandomSongFromPlaylist(playlistName);
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
    final playlist = _musicTracks[lastTrack.playlist];
    if (playlist?.isNotEmpty != true) {
      return null;
    }

    final playlistCopy = List<MusicTrack>.from(playlist!);
    playlistCopy.remove(lastTrack);

    final playlistToUse = playlistCopy.isEmpty ? playlist : playlistCopy;
    return playlistToUse[Random().nextInt(playlistToUse.length)];
  }

  MusicTrack? _selectRandomSongFromPlaylist(MusicPlaylist playlistName) {
    final playlist = _musicTracks[playlistName];
    if (playlist?.isNotEmpty != true) {
      return null;
    }

    return playlist![Random().nextInt(playlist.length)];
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
