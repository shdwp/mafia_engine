import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';

import '../game_viewmodel.dart';
import '../game_widgets.dart';

class GameNightStartViewModel extends GameFrameViewModel<GameFrameNightStart> {
  GameNightStartViewModel(super.gameViewModel, super.lastFrame);
}

class GameScreenNightStartWidget extends StatelessWidget {
  const GameScreenNightStartWidget({super.key, required this.viewModel});
  final GameNightStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("🌙", style: TextStyle(fontSize: 72)));
  }
}

class GameNightRoleActionViewModel
    extends GameFrameViewModel<GameFrameNightRoleAction> {
  GameNightRoleActionViewModel(super.gameViewModel, super.lastFrame) {
    targetPlayers = state.players.map(
      (p) => GamePlayerSelectorViewModel(p, true, p.index == current.index),
    );
  }

  Iterable<GamePlayerSelectorViewModel> targetPlayers = List.empty();
  Iterable<GamePlayer> get actionablePlayers => current.role == GameRole.mafia
      ? state.players.where(
          (p) => p.role == GameRole.mafia || p.role == GameRole.don,
        )
      : state.players.whereRole(current.role);

  bool get isBlocked {
    var isBlocked = false;

    for (final player in actionablePlayers) {
      var blockedRole = state.priestBlockedPlayer?.role;
      if (blockedRole?.isMafia == true) {
        isBlocked = player.role.isMafia;
      }

      if (state.priestBlockedPlayer == player) isBlocked = true;
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
        GamePlayerListWidget(
          players: viewModel.actionablePlayers,
          showRoles: true,
          vertical: false,
        ),
        Visibility(
          visible: viewModel.isBlocked,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadiusGeometry.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "BLOCKED",
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
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
