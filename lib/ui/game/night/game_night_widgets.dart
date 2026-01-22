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
    return Text("Night starts!");
  }
}

class GameNightRoleActionViewModel
    extends GameFrameViewModel<GameFrameNightRoleAction> {
  GameNightRoleActionViewModel(super.gameViewModel, super.lastFrame) {
    targetPlayers = state.players.map(
      (p) => GamePlayerSelectorViewModel(p, true, p.index == current.index),
    );
  }

  GameRole get role => current.role;
  Iterable<GamePlayerSelectorViewModel> targetPlayers = List.empty();
  Iterable<GamePlayer> get actionablePlayers => current.role == GameRole.mafia
      ? state.players.where(
          (p) => p.role == GameRole.mafia || p.role == GameRole.don,
        )
      : state.players.whereRole(current.role);

  bool isBlocked(GamePlayer player) {
    return state.priestBlockedPlayer == player;
  }

  void select(int index) {
    current.index = index;
	setDirty();
  }
}

class GameScreenNightRoleActionWidget extends StatelessWidget {
  const GameScreenNightRoleActionWidget({super.key, required this.viewModel});
  final GameNightRoleActionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    List<Widget> actionablePlayerWidgets = [];
    for (final player in viewModel.actionablePlayers) {
      actionablePlayerWidgets.add(
        Text(
          "#${player.seatName} ${viewModel.isBlocked(player) ? "BLOCKED" : ""}",
        ),
      );
    }

    return Column(
      children: [
        Text(viewModel.role.toString()),
        Row(children: actionablePlayerWidgets),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: viewModel.targetPlayers,
              onPress: (index) => viewModel.select(index),
            ),
          ),
        ),
      ],
    );
  }
}
