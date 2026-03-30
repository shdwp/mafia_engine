import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';

class GameStartViewModel extends GameFrameViewModel<GameFrameStart> {
  GameStartViewModel(super.gameViewModel, super.current);

  String get currentName => current.gameName;

  void setName(String name) {
    current.gameName = name;
    notifyListeners();
  }

  void setToDate() {
    final DateFormat formatter = DateFormat("MMM d");
    current.gameName = formatter.format(DateTime.now());
    notifyListeners();
  }

  void setToDateTime() {
    final DateFormat formatter = DateFormat("MMM d, HH:mm");
    current.gameName = formatter.format(DateTime.now());
    notifyListeners();
  }

  void addTableSuffix(int table) {
    current.gameName = "${current.gameName} Table $table";
    notifyListeners();
  }

  void addGameSuffix(int game) {
    current.gameName = "${current.gameName} Game $game";
    notifyListeners();
  }
}

class GameStartWidget extends StatelessWidget {
  final GameStartViewModel viewModel;

  const GameStartWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final config = context.read<GameConfigService>();

    final tableWidgets = List.generate(config.amountOfTables, (index) {
      final tableIndex = index + 1;
      return ElevatedButton(
        onPressed: () => viewModel.addTableSuffix(tableIndex),
        child: Text("$tableIndex"),
      );
    });

    final gameWidgets = List.generate(config.maxAmountOfGames, (index) {
      final tableIndex = index + 1;
      return ElevatedButton(
        onPressed: () => viewModel.addGameSuffix(tableIndex),
        child: Text("$tableIndex"),
      );
    });

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          Text("🎲", style: TextStyle(fontSize: 72)),
          Text(
            "File: ${viewModel.current.fileName}",
            style: TextStyle(fontSize: 22),
          ),
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => FractionallySizedBox(
              widthFactor: 0.7,
              child: TextField(
                controller: TextEditingController.fromValue(
                  TextEditingValue(text: viewModel.currentName),
                ),
                decoration: InputDecoration(labelText: "Name"),
                onChanged: (value) => viewModel.setName(value),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => viewModel.setToDate(),
                child: Text("Set to date"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setToDateTime(),
                child: Text("Set to date time"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setName(""),
                child: Text("Clear"),
              ),
            ],
          ),
          Text("Add table suffix:"),
          Row(mainAxisSize: MainAxisSize.min, children: tableWidgets),
          Text("Add game suffix:"),
          Row(mainAxisSize: MainAxisSize.min, children: gameWidgets),
        ],
      ),
    );
  }
}

class GameAddPlayersViewModel extends GameFrameViewModel<GameFrameAddPlayers> {
  GameAddPlayersViewModel(super.gameViewModel, super.lastFrame);

  GameCriticalDayCalculation calculateCriticalDay() {
    return GameState.calculateCriticalDay(
      current.players.length,
      current.roles,
    );
  }

  void addEmptyPlayer() {
    current.players.add("");
    setDirty();
  }

  void movePlayerUp(int index) {
    if (index <= 0) return;
    final value = current.players.removeAt(index);
    current.players.insert(index - 1, value);
    setDirty();
  }

  void movePlayerDown(int index) {
    if (index >= current.players.length - 1) return;
    final value = current.players.removeAt(index);
    current.players.insert(index + 1, value);
    setDirty();
  }

  void removePlayer(int index) {
    current.players.removeAt(index);
    setDirty();
  }

  bool roleEnabled(GameRole role) {
    return current.roles.contains(role);
  }

  void setName(int index, String name) {
    current.players[index] = name.trim();
  }

  void toggleRole(GameRole role) {
    if (current.roles.contains(role)) {
      current.roles.remove(role);
    } else {
      current.roles.add(role);
    }
    setDirty();
  }
}

class GameScreenAddPlayersWidget extends StatefulWidget {
  const GameScreenAddPlayersWidget({super.key, required this.viewModel});
  final GameAddPlayersViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenInputPlayersState();
}

class _GameScreenInputPlayersState extends State<GameScreenAddPlayersWidget> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        final criticalCalculation = widget.viewModel.calculateCriticalDay();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsetsGeometry.all(10),
                itemBuilder: (context, index) {
                  return Row(
                    spacing: 10,
                    children: [
                      Text(GamePlayer.seatNameFromIndex(index)),
                      Expanded(
                        child: Autocomplete(
                          optionsBuilder: (value) {
                            widget.viewModel.setName(index, value.text);
                            return context
                                .read<GameRepository>()
                                .suggestPlayerNames(value.text);
                          },
                          onSelected: (value) {
                            widget.viewModel.setName(index, value);
                          },
                          initialValue: TextEditingValue(
                            text: widget.viewModel.current.players[index],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                widget.viewModel.movePlayerUp(index),
                            icon: Text("↑"),
                          ),
                          IconButton(
                            onPressed: () =>
                                widget.viewModel.movePlayerDown(index),
                            icon: Text("↓"),
                          ),
                          IconButton(
                            onPressed: () =>
                                widget.viewModel.removePlayer(index),
                            icon: Text("☒"),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                itemCount: widget.viewModel.current.players.length,
              ),
            ),
            IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          widget.viewModel.toggleRole(GameRole.priest),
                      icon: GamePlayerRoleWidget(
                        role: GameRole.priest,
                        enabled: widget.viewModel.roleEnabled(GameRole.priest),
                      ),
                    ),
                    VerticalDivider(),
                    IconButton(
                      onPressed: () =>
                          widget.viewModel.toggleRole(GameRole.doctor),
                      icon: GamePlayerRoleWidget(
                        role: GameRole.doctor,
                        enabled: widget.viewModel.roleEnabled(GameRole.doctor),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          widget.viewModel.toggleRole(GameRole.killer),
                      icon: GamePlayerRoleWidget(
                        role: GameRole.killer,
                        enabled: widget.viewModel.roleEnabled(GameRole.killer),
                      ),
                    ),

                    VerticalDivider(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.6,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  itemBuilder: (context, index) => Center(
                                    child: Text(
                                      criticalCalculation.log[index],
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  itemCount: criticalCalculation.log.length,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: GamePlayerRoleWidget(
                          role: GameRole.civilian,
                          textOverride: criticalCalculation.votingAttempts
                              .toString(),
                        ),
                      ),
                    ),
                    FilledButton(
                      child: Text("Add"),
                      onPressed: () {
                        widget.viewModel.addEmptyPlayer();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
