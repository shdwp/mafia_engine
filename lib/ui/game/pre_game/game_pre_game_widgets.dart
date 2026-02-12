import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';

class GameAddPlayersViewModel extends GameFrameViewModel<GameFrameAddPlayers> {
  GameAddPlayersViewModel(super.gameViewModel, super.lastFrame);

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
    setDirty();
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
                        FilledButton.tonal(
                          onPressed: () => widget.viewModel.movePlayerUp(index),
                          child: Text("↑"),
                        ),
                        FilledButton.tonal(
                          onPressed: () =>
                              widget.viewModel.movePlayerDown(index),
                          child: Text("↓"),
                        ),
                        FilledButton.tonal(
                          onPressed: () => widget.viewModel.removePlayer(index),
                          child: Text("☒"),
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
                  TextButton(
                    onPressed: () =>
                        widget.viewModel.toggleRole(GameRole.priest),
                    child: GamePlayerRoleWidget(
                      role: GameRole.priest,
                      enabled: widget.viewModel.roleEnabled(GameRole.priest),
                    ),
                  ),
                  VerticalDivider(),
                  TextButton(
                    onPressed: () =>
                        widget.viewModel.toggleRole(GameRole.doctor),
                    child: GamePlayerRoleWidget(
                      role: GameRole.doctor,
                      enabled: widget.viewModel.roleEnabled(GameRole.doctor),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        widget.viewModel.toggleRole(GameRole.killer),
                    child: GamePlayerRoleWidget(
                      role: GameRole.killer,
                      enabled: widget.viewModel.roleEnabled(GameRole.killer),
                    ),
                  ),

                  VerticalDivider(),
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
      ),
    );
  }
}
