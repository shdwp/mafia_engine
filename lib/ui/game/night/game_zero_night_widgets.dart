import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

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
            child: GamePlayerRoleWidget(role: role, fontSize: 24),
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
          spacing: 16,
          children: [
            GamePlayerBadgeWidget(
              player: widget.viewModel.player,
              showRole: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Current: ", style: TextStyle(fontSize: 21)),
                GamePlayerRoleWidget(role: widget.viewModel.role),
              ],
            ),
            Divider(),
            Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: redRoleWidgets,
            ),
            Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: blackRoleWidgets,
            ),
            Row(
              spacing: 16,
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

  GameRole get role => current.roleGroup;
  Iterable<GamePlayer> get players => role == GameRole.mafia
      ? state.players.whereMafia()
      : state.players.whereRole(role);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().zeroNightMeetTimer,
          playSounds: false,
        ),
        GamePlayerListWidget(
          players: widget.viewModel.players,
          showRoles: true,
        ),
      ],
    );
  }
}
