import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';

class BackupTimerViewModel extends ChangeNotifier {
  final GameTimer timer;
  int timeInSeconds = 60;

  BackupTimerViewModel(this.timer);

  void setTimeInSeconds(int seconds) {
    timeInSeconds = seconds;
    timer.start(timeInSeconds);
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
          GameTimerWidget(timeInSeconds: viewModel.timeInSeconds),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(60),
            child: Text("60s"),
          ),
          FilledButton(
            onPressed: () => viewModel.setTimeInSeconds(30),
            child: Text("30s"),
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
