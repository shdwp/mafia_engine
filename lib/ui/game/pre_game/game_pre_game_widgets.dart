import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_frame.dart';

import '../game_viewmodel.dart';

class GameAddPlayersViewModel extends GameFrameViewModel<GameFrameAddPlayers> {
  GameAddPlayersViewModel(super.gameViewModel, super.lastFrame);

  void addEmptyPlayer() {
    current.players.add("Empty");
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
                    Text(index.toString()),
                    Text(widget.viewModel.current.players[index]),
                    ElevatedButton(
                      onPressed: () => widget.viewModel.movePlayerUp(index),
                      child: Text("UP"),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.viewModel.movePlayerDown(index),
                      child: Text("DOWN"),
                    ),
                  ],
                );
              },
              itemCount: widget.viewModel.current.players.length,
            ),
          ),
          Center(
            child: Row(
              children: [
                FilledButton(
                  child: Text("Add"),
                  onPressed: () {
                    widget.viewModel.addEmptyPlayer();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
