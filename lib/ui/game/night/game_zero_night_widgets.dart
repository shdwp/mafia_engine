import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';

import '../game_viewmodel.dart';

class GameAssignRoleViewModel extends GameFrameViewModel<GameFrameAssignRole> {
  GameAssignRoleViewModel(super.gameViewModel, super.lastFrame);

  GamePlayer get player => state.players[current.index];
  GameRole get role => current.role;
  Iterable<GameRole> get allRoles => state.rolesInTheGame;

  void assign(GameRole role) {
    current.role = role;
    setDirty();
    gameViewModel.moveForward();
  }

  bool showRole(GameRole role) {
    return state.rolesInTheGame.contains(role);
  }
}

class GameScreenAssignRoleWidget extends StatefulWidget {
  const GameScreenAssignRoleWidget({super.key, required this.viewModel});
  final GameAssignRoleViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenAssignRoleState();
}

class _GameScreenAssignRoleState extends State<GameScreenAssignRoleWidget> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        var redRoleWidgets = <Widget>[];
        var blackRoleWidgets = <Widget>[];
        var otherRoleWidgets = <Widget>[];
        for (final role in widget.viewModel.allRoles) {
          var roleWidget = TextButton(
            onPressed: () => widget.viewModel.assign(role),
            child: GamePlayerRoleWidget(role: role),
          );

          if (role.isCivilian) {
            redRoleWidgets.add(roleWidget);
          } else if (role.isMafia) {
            blackRoleWidgets.add(roleWidget);
          } else {
            otherRoleWidgets.add(roleWidget);
          }
        }

        return Column(
          children: [
            Text(widget.viewModel.player.seatName),
            Text(widget.viewModel.player.name),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Current: "),
                GamePlayerRoleWidget(role: widget.viewModel.role),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: redRoleWidgets,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: blackRoleWidgets,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: otherRoleWidgets,
            ),
          ],
        );
      },
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
  const GameScreenZeroNightMeetWidget({super.key, required this.viewModel});
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
