import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';

class GameNarratorStateOverrideViewModel
    extends GameFrameViewModel<GameFrameNarratorStateOverride> {
  GameNarratorStateOverrideViewModel(super.gameViewModel, super.current)
    : type = GameFrameNarratorStateOverrideType.dayStart,
      roles = gameViewModel.state.rolesInTheGame;

  GameFrameNarratorStateOverrideType type;
  List<GameRole> roles;

  void setAlive(int index, bool alive) {
    var player = current.players[index];
    current.players[index] = (player.$1, player.$2, alive, player.$4);
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
}

class GameScreenNarratorStateOverrideWidget extends StatelessWidget {
  const GameScreenNarratorStateOverrideWidget({
    super.key,
    required this.viewModel,
  });

  final GameNarratorStateOverrideViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsetsGeometry.all(10),
              itemBuilder: (context, index) {
                return Row(
                  spacing: 10,
                  children: [
                    Text(GamePlayer.seatNameFromIndex(index)),
                    Text(viewModel.current.players[index].$1),
                    IconButton(
                      onPressed: () => viewModel.cycleRole(index),
                      icon: GamePlayerRoleWidget(
                        role: viewModel.getRole(index),
                      ),
                    ),
                  ],
                );
              },
              itemCount: viewModel.current.players.length,
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
      (p) => GamePlayerSelectorViewModel(p, true, current.index == p.index),
    );
  }

  Iterable<GamePlayerSelectorViewModel> players = List.empty();
  String? get currentAmount =>
      (current.index != null ? state.players[current.index!].penalties : null)
          .toString();

  void select(int index) {
    current.index = index;
    setDirty();
  }

  void setPenaltyAmount(int amount) {
    current.amount = amount;
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
          Expanded(
            child: GamePlayerSelectorWidget(
              players: viewModel.players,
              onPress: (index) => viewModel.select(index),
            ),
          ),
          Text(viewModel.currentAmount ?? "No player"),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(1),
                child: Text("+1"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(2),
                child: Text("+2"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(3),
                child: Text("+3"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(4),
                child: Text("+4"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(0),
                child: Text("0"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-1),
                child: Text("-1"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-2),
                child: Text("-2"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-3),
                child: Text("-3"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-4),
                child: Text("-4"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
