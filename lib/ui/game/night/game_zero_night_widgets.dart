import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';

import '../game_viewmodel.dart';

class GameAssignRoleViewModel extends GameFrameViewModel<GameFrameAssignRole> {
  GameAssignRoleViewModel(super.gameViewModel, super.lastFrame);

  GamePlayer get player => state.players[current.index];
  String get role => "${current.role}";

  void assign(GameRole role) {
    current.role = role;
    setDirty();
    gameViewModel.moveForward();
  }
}

class GameScreenAssignRoleWidget extends StatefulWidget {
  const GameScreenAssignRoleWidget({required this.viewModel});
  final GameAssignRoleViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenAssignRoleState();
}

class _GameScreenAssignRoleState extends State<GameScreenAssignRoleWidget> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) => Column(
        children: [
          Text(widget.viewModel.player.seatName),
          Text(widget.viewModel.player.name),
          Text(widget.viewModel.role),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.civilian),
            child: Text("Citizen"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.mafia),
            child: Text("Mafia"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.don),
            child: Text("Don"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.priest),
            child: Text("Priest"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.sheriff),
            child: Text("Sheriff"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.doctor),
            child: Text("Doctor"),
          ),
          ElevatedButton(
            onPressed: () => widget.viewModel.assign(GameRole.killer),
            child: Text("Killer"),
          ),
        ],
      ),
    );
  }
}

class GameZeroNightMeetViewModel
    extends GameFrameViewModel<GameFrameZeroNightMeet> {
  GameZeroNightMeetViewModel(super.gameViewModel, super.lastFrame);

  String get role => current.roleGroup.toString();
  String get seats =>
      ""; // lastState.players .map((p) => p.seatName).join(", ");
}

class GameScreenZeroNightMeetWidget extends StatefulWidget {
  const GameScreenZeroNightMeetWidget({required this.viewModel});
  final GameZeroNightMeetViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenZeroNightMeetState();
}

class _GameScreenZeroNightMeetState
    extends State<GameScreenZeroNightMeetWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Text(widget.viewModel.role), Text(widget.viewModel.seats)],
    );
  }
}
