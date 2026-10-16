import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';

class GameCompensationImmunitiesViewModel
    extends GameFrameViewModel<GameFrameCompensationImmunities> {
  GameCompensationImmunitiesViewModel(super.gameViewModel, super.current);

  Iterable<GamePlayerSelectorViewModel> get players => state.players.map(
    (p) => GamePlayerSelectorViewModel(
      p,
      available: true,
      selected: current.playerIndices.contains(p.index),
    ),
  );

  void toggle(int index) {
    if (current.playerIndices.contains(index)) {
      current.playerIndices.remove(index);
    } else {
      current.playerIndices.add(index);
    }
    setDirty();
  }
}

class GameScreenCompensationImmunitiesWidget extends StatelessWidget {
  const GameScreenCompensationImmunitiesWidget({
    super.key,
    required this.viewModel,
  });

  final GameCompensationImmunitiesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => GamePlayerSelectorWidget(
        players: viewModel.players,
        showRoles: false,
        onPress: (index) => viewModel.toggle(index),
      ),
    );
  }
}

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
  static const _roleOrder = [
    GameRole.civilian,
    GameRole.sheriff,
    GameRole.doctor,
    GameRole.mafia,
    GameRole.don,
    GameRole.priest,
    GameRole.killer,
  ];

  static const _roleNames = {
    GameRole.civilian: "Цивільний",
    GameRole.sheriff: "Шериф",
    GameRole.doctor: "Лікар",
    GameRole.mafia: "Мафія",
    GameRole.don: "Дон",
    GameRole.priest: "Священник",
    GameRole.killer: "Кілер",
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        return Column(
          spacing: 8,
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
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      for (final role in _roleOrder)
                        if (widget.viewModel.showRole(role))
                          TextButton(
                            onPressed: () => widget.viewModel.assign(role),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  GameUILib.roleViewModel(role).background,
                              foregroundColor:
                                  GameUILib.roleViewModel(role).foreground,
                              padding: const EdgeInsets.all(16),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _roleNames[role] ??
                                  GameUILib.roleViewModel(role).name,
                              style: const TextStyle(fontSize: 21),
                            ),
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
          key: ValueKey(widget.viewModel.current.id),
          players: widget.viewModel.players,
          showRoles: true,
          initiallyMasked: context.read<GameConfigService>().tapToRevealNightRoles,
        ),
      ],
    );
  }
}
