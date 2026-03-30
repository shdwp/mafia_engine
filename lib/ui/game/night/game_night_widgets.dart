import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/music_service.dart';
import 'package:mafia_engine/ui/game/narrator/game_narrator_widgets.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';
import '../game_widgets.dart';

class GameNightStartViewModel extends GameFrameViewModel<GameFrame> {
  final GameController _controller;

  GameNightStartViewModel(
    super.gameViewModel,
    super.lastFrame,
    this._controller,
  );

  MusicPlaylist get musicPlaylist => _controller.playlistForFrame(current);
}

class GameScreenNightStartWidget extends StatelessWidget {
  const GameScreenNightStartWidget({super.key, required this.viewModel});
  final GameNightStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().nightActionTimer,
          playSounds: false,
          autoStart: false,
        ),
        MusicPlayerWidget(
          viewModel: MusicPlayerViewModel(
            musicService: context.read(),
            playlist: viewModel.musicPlaylist,
            showPlaylist: true,
          ),
        ),
      ],
    );
  }
}

class GameDayStartViewModel extends GameFrameViewModel<GameFrameDayStart> {
  final GameController _controller;

  GameDayStartViewModel(
    super.gameViewModel,
    super.lastFrame,
    GameController controller,
  ) : _controller = controller;

  MusicPlaylist get musicPlaylist => _controller.playlistForFrame(current);
}

class GameScreenDayStartWidget extends StatelessWidget {
  const GameScreenDayStartWidget({super.key, required this.viewModel});
  final GameDayStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("☀️", style: TextStyle(fontSize: 72)),
          GameTimerWidget(
            timeInSeconds: context.read<GameConfigService>().speechTimer,
            playSounds: false,
            autoStart: false,
          ),
          MusicPlayerWidget(
            viewModel: MusicPlayerViewModel(
              musicService: context.read(),
              playlist: viewModel.musicPlaylist,
            ),
          ),
        ],
      ),
    );
  }
}

class GameNightRoleActionViewModel
    extends GameFrameViewModel<GameFrameNightRoleAction> {
  GameNightRoleActionViewModel(super.gameViewModel, super.lastFrame) {
    targetPlayers = state.players.map(
      (p) => GamePlayerSelectorViewModel(
        p,
        available: true,
        selected: p.index == current.index,
      ),
    );
  }

  Iterable<GamePlayerSelectorViewModel> targetPlayers = List.empty();
  Iterable<GamePlayer> get actionablePlayers => current.role == GameRole.mafia
      ? state.players.where(
          (p) => p.role == GameRole.mafia || p.role == GameRole.don,
        )
      : state.players.whereRole(current.role);

  GamePlayer? get lastTarget {
    if (current.role == GameRole.priest) {
      return state.lastPriestBlock != null
          ? state.players[state.lastPriestBlock!]
          : null;
    }

    if (current.role == GameRole.doctor) {
      return state.lastDoctorHeal != null
          ? state.players[state.lastDoctorHeal!]
          : null;
    }

    return null;
  }

  bool get isBlocked {
    var isBlocked = false;

    for (final player in actionablePlayers) {
      var blockedRole = state.currentNightBlockedPlayer?.role;
      if (blockedRole?.isMafia == true) {
        isBlocked = player.role.isMafia;
      }

      if (state.currentNightBlockedPlayer == player) isBlocked = true;
    }

    return isBlocked;
  }

  void toggleSelect(int index) {
    current.index = current.index == index ? null : index;
    setDirty();
  }
}

class GameScreenNightRoleActionWidget extends StatelessWidget {
  const GameScreenNightRoleActionWidget({super.key, required this.viewModel});
  final GameNightRoleActionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().nightActionTimer,
          playSounds: false,
        ),
        GamePlayerListWidget(
          players: viewModel.actionablePlayers,
          showRoles: true,
          vertical: true,
        ),
        if (viewModel.lastTarget != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadiusGeometry.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Last target: ", style: TextStyle(fontSize: 18)),
                  GamePlayerBadgeWidget(
                    player: viewModel.lastTarget!,
                    showRole: true,
                  ),
                ],
              ),
            ),
          ),

        if (viewModel.isBlocked)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadiusGeometry.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "BLOCKED",
                style: TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          ),

        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: viewModel.targetPlayers,
              showRoles: true,
              onPress: (index) => viewModel.toggleSelect(index),
            ),
          ),
        ),
      ],
    );
  }
}
