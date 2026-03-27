import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:mafia_engine/data/music_service.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

class BackupTimerViewModel extends ChangeNotifier {
  final GameTimer timer;
  int timeInSeconds = 60;

  BackupTimerViewModel(this.timer);

  void setTimeInSeconds(int seconds) {
    timeInSeconds = seconds;
    timer.start(timeInSeconds, playSounds: false);
    notifyListeners();
  }
}

class BackupTimerWidget extends StatelessWidget {
  final BackupTimerViewModel viewModel;

  const BackupTimerWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          GameTimerWidget(
            timeInSeconds: viewModel.timeInSeconds,
            playSounds: false,
            autoStart: false,
          ),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(60),
            child: Text("60s"),
          ),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(30),
            child: Text("30s"),
          ),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(30),
            child: Text("20s"),
          ),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(10),
            child: Text("10s"),
          ),
        ],
      ),
    );
  }
}

class MusicPlayerViewModel extends ChangeNotifier {
  final MusicService _service;
  final Function(MusicPlaylist playlistName)? onPlaylistChanged;
  final bool showPlaylist;
  MusicPlaylist playlist;

  String get title => _service.currentTrackTitle ?? "Not playing";
  String get progressText {
    if (_service.currentTrackPosition == null ||
        _service.currentTrackDuration == null) {
      return "00:00 / 00:00";
    }

    return "${GameUILib.formatMinutesSeconds(_service.currentTrackPosition!.ceil())} / ${GameUILib.formatMinutesSeconds(_service.currentTrackDuration!.ceil())}";
  }

  bool get hasPlayback => _service.hasPlayback;
  bool get isPaused => _service.isPaused;

  ChangeNotifier get musicServiceListenable => _service.progressNotifier;

  MusicPlayerViewModel({
    required MusicService musicService,
    required this.playlist,
    this.showPlaylist = false,
    this.onPlaylistChanged,
  }) : _service = musicService {
    if (musicService.currentPlaylist != null) {
      playlist = musicService.currentPlaylist!;
    }
  }

  String playlistName(MusicPlaylist playlist) {
    switch (playlist) {
      case MusicPlaylist.invalid:
        return "invalid";
      case MusicPlaylist.preparation:
        return "Prep";
      case MusicPlaylist.lowIntensity:
        return "Low";
      case MusicPlaylist.mediumIntensity:
        return "Med";
      case MusicPlaylist.highIntensity:
        return "High";
      case MusicPlaylist.special:
        return "Spec";
    }
  }

  int playlistCount(MusicPlaylist playlist) {
    return _service.iterateTracksInPlaylist(playlist).length;
  }

  void togglePause() {
    _service.togglePause();
    notifyListeners();
  }

  void stopMusic() {
    _service.stopWithFadeOut();
    notifyListeners();
  }

  void startMusic() {
    _service.startWithFadeInFromPlaylist(playlist);
    notifyListeners();
  }

  void skipTrack() {
    _service.skipWithCrossfade();
    notifyListeners();
  }

  void fastForward() {
    _service.fastForward();
    notifyListeners();
  }

  void setPlaylist(MusicPlaylist playlist) {
    this.playlist = playlist;
    if (onPlaylistChanged != null) onPlaylistChanged!(playlist);
    notifyListeners();
  }

  Iterable<MusicPlaylist> displayedPlaylists() sync* {
    for (final playlist in MusicPlaylist.values) {
      if (playlist == MusicPlaylist.invalid) continue;
      if (!_service.checkPlaylistHaveSongs(playlist)) continue;

      yield playlist;
    }
  }
}

class MusicPlayerWidget extends StatelessWidget {
  final MusicPlayerViewModel viewModel;

  const MusicPlayerWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final playlistViewModel = MusicPlayerPlaylistViewModel(
      service: context.read(),
      playlist: viewModel.playlist,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.musicServiceListenable,
          ]),
          builder: (context, child) {
            final playlistButtons = <Widget>[];
            for (final playlist in viewModel.displayedPlaylists()) {
              final title = Text(viewModel.playlistName(playlist));

              if (playlist == viewModel.playlist) {
                playlistButtons.add(
                  FilledButton(onPressed: () {}, child: title),
                );
              } else {
                playlistButtons.add(
                  ElevatedButton(
                    onPressed: () {
                      viewModel.setPlaylist(playlist);
                      playlistViewModel.changePlaylistToDisplay(playlist);
                    },
                    child: title,
                  ),
                );
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewModel.title,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                Text(
                  viewModel.progressText,
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: viewModel.hasPlayback
                          ? () => viewModel.stopMusic()
                          : null,
                      child: Icon(Icons.stop),
                    ),

                    if (!viewModel.hasPlayback)
                      FilledButton(
                        onPressed: () => viewModel.startMusic(),
                        child: Icon(Icons.play_arrow),
                      ),

                    if (viewModel.hasPlayback)
                      FilledButton(
                        onPressed: () => viewModel.togglePause(),
                        child: Icon(
                          viewModel.isPaused ? Icons.play_arrow : Icons.pause,
                        ),
                      ),

                    FilledButton(
                      onPressed: viewModel.hasPlayback
                          ? () => viewModel.skipTrack()
                          : null,
                      child: Icon(Icons.skip_next),
                    ),
                    FilledButton(
                      onPressed: viewModel.hasPlayback
                          ? () => viewModel.fastForward()
                          : null,
                      child: Icon(Icons.fast_forward),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(spacing: 4, children: playlistButtons),
                  ),
                ),
              ],
            );
          },
        ),

        if (viewModel.showPlaylist)
          MusicPlayerPlaylistWidget(viewModel: playlistViewModel),
      ],
    );
  }
}

class MusicPlayerPlaylistViewModel extends ChangeNotifier {
  final MusicService _service;
  MusicPlaylist playlist;

  MusicPlayerPlaylistViewModel({
    required MusicService service,
    required this.playlist,
  }) : _service = service;

  Iterable<MusicTrack> get displayTracks =>
      _service.iterateTracksInPlaylist(playlist);

  ChangeNotifier get musicServiceListenable => _service.progressNotifier;

  void changePlaylistToDisplay(MusicPlaylist playlist) {
    this.playlist = playlist;
    notifyListeners();
  }

  void playTrack(MusicTrack track) {
    _service.startTrackWithFadeIn(track);
  }

  bool isTrackCurrent(MusicTrack track) {
    return _service.currentTrack == track;
  }

  String trackInfo(MusicTrack track) {
    var result = "";

    if (track.skipLeading != null) {
      result += "L${track.skipLeading!.inSeconds}";
    }

    if (track.skipTrailing != null) {
      result += "T${track.skipTrailing!.inSeconds}";
    }

    if (track.volumeAdjustment != null) {
      result += "V${track.volumeAdjustment}";
    }

    return result;
  }
}

class MusicPlayerPlaylistWidget extends StatelessWidget {
  final MusicPlayerPlaylistViewModel viewModel;

  const MusicPlayerPlaylistWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.musicServiceListenable,
          ]),
          builder: (context, child) => ListView.builder(
            itemCount: viewModel.displayTracks.length,
            itemBuilder: (context, index) {
              final track = viewModel.displayTracks.elementAt(index);
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      track.title,
                      style: TextStyle(
                        fontWeight: viewModel.isTrackCurrent(track)
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    viewModel.trackInfo(track),
                    style: TextStyle(color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: viewModel.isTrackCurrent(track)
                        ? null
                        : () => viewModel.playTrack(track),
                    icon: Icon(Icons.play_circle),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class GameNarratorStateOverrideViewModel
    extends GameFrameViewModel<GameFrameNarratorStateOverride> {
  GameNarratorStateOverrideViewModel(super.gameViewModel, super.current)
    : roles = gameViewModel.state.rolesInTheGame;

  List<GameRole> roles;

  void setAlive(int index, bool alive) {
    var player = current.players[index];
    current.players[index] = (player.$1, player.$2, alive, player.$4);
    setDirty();
  }

  GameRole getRole(int index) => current.players[index].$2;

  void cycleRole(int index) {
    var player = current.players[index];
    var roleIndex = state.rolesInTheGame.indexOf(player.$2);
    var role =
        state.rolesInTheGame[roleIndex + 1 >= state.rolesInTheGame.length
            ? 0
            : roleIndex + 1];

    current.players[index] = (player.$1, role, player.$3, player.$4);
    setDirty();
  }

  void setType(GameFrameNarratorStateOverrideType? type) {
    current.type = type ?? GameFrameNarratorStateOverrideType.dayStart;
    setDirty();
  }

  void setFirstToTalk(int index) {
    current.firstToTalk = index;
    setDirty();
  }
}

class GameScreenNarratorStateOverrideWidget extends StatelessWidget {
  const GameScreenNarratorStateOverrideWidget({
    super.key,
    required this.viewModel,
  });

  final GameNarratorStateOverrideViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    var options = <int>[];
    for (int i = 0; i < viewModel.state.players.length; i++) {
      options.add(i);
    }

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text("Start:"),
              SegmentedButton(
                segments: [
                  ButtonSegment<GameFrameNarratorStateOverrideType>(
                    value: GameFrameNarratorStateOverrideType.dayStart,
                    icon: Icon(Icons.sunny),
                  ),
                  ButtonSegment<GameFrameNarratorStateOverrideType>(
                    value: GameFrameNarratorStateOverrideType.nightStart,
                    icon: Icon(Icons.mode_night),
                  ),
                ],
                selected: {viewModel.current.type},
                onSelectionChanged: (value) =>
                    viewModel.setType(value.firstOrNull),
              ),
              Text("Next talk:"),
              DropdownButton(
                items: options.map((index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(GamePlayer.seatNameFromIndex(index)),
                  );
                }).toList(),
                value: viewModel.current.firstToTalk,
                onChanged: (value) {
                  if (value != null) viewModel.setFirstToTalk(value);
                },
              ),
            ],
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsetsGeometry.all(8),
              itemCount: viewModel.current.players.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                var player = viewModel.current.players[index];
                var decoration = player.$3 ? null : TextDecoration.lineThrough;
                var seatName =
                    "${GamePlayer.seatNameFromIndex(index)}${!player.$3 ? GameUILib.deadSymbol : ""}";

                return Row(
                  spacing: 16,
                  children: [
                    Text(seatName),
                    Expanded(
                      child: Text(
                        player.$1,
                        style: TextStyle(decoration: decoration),
                      ),
                    ),
                    Checkbox(
                      value: player.$3,
                      onChanged: (value) =>
                          viewModel.setAlive(index, value ?? true),
                    ),
                    IconButton(
                      onPressed: () => viewModel.cycleRole(index),
                      icon: GamePlayerRoleWidget(
                        role: viewModel.getRole(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GameNarratorPenalizeViewModel
    extends GameFrameViewModel<GameFrameNarratorPenalize> {
  GameNarratorPenalizeViewModel(super.gameViewModel, super.current) {
    players = state.players.map(
      (p) => GamePlayerSelectorViewModel(
        p,
        available: true,
        selected: current.index == p.index,
      ),
    );

    if (current.index != null) selectedPlayer = state.players[current.index!];
  }

  Iterable<GamePlayerSelectorViewModel> players = List.empty();
  String get currentAmount => current.amount.toString();

  GamePlayer? selectedPlayer;

  void select(int index) {
    current.index = index;
    selectedPlayer = state.players[index];
    current.amount = 0;
    setDirty();
  }

  void adjustPenalty(int amount) {
    current.amount += amount;
    setDirty();
  }
}

class GameScreenNarratorPenalizeWidget extends StatelessWidget {
  const GameScreenNarratorPenalizeWidget({super.key, required this.viewModel});

  final GameNarratorPenalizeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => Column(
        children: [
          if (viewModel.selectedPlayer != null)
            GamePlayerBadgeWidget(player: viewModel.selectedPlayer!),
          Expanded(
            child: GamePlayerSelectorWidget(
              players: viewModel.players,
              showRoles: true,
              onPress: (index) => viewModel.select(index),
            ),
          ),
          Text(
            viewModel.selectedPlayer != null
                ? "Added penalty points: ${viewModel.currentAmount}"
                : "Player not selected",
            style: TextStyle(fontSize: 18),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () => viewModel.adjustPenalty(-1),
                  child: Text("-"),
                ),
                FilledButton(
                  onPressed: () => viewModel.adjustPenalty(1),
                  child: Text("+"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
