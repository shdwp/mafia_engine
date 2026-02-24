import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

import 'day/game_day_widgets.dart';
import 'narrator/game_narrator_widgets.dart';
import 'night/game_night_widgets.dart';
import 'night/game_zero_night_widgets.dart';
import 'pre_game/game_pre_game_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.viewModel});
  final GameViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenGameState();
}

class _GameScreenGameState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        Widget frameWidget = Text(
          "Error: frame ${widget.viewModel.current.runtimeType.toString} resulted in no widget!",
        );
        switch (widget.viewModel.current) {
          case GameFrameStart frame:
            frameWidget = GameStartWidget(
              viewModel: GameStartViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameNarratorPenalize frame:
            frameWidget = GameScreenNarratorPenalizeWidget(
              viewModel: GameNarratorPenalizeViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameNarratorStateOverride frame:
            frameWidget = GameScreenNarratorStateOverrideWidget(
              viewModel: GameNarratorStateOverrideViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;
          case GameFrameAddPlayers frame:
            frameWidget = GameScreenAddPlayersWidget(
              viewModel: GameAddPlayersViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameAssignRole frame:
            frameWidget = GameScreenAssignRoleWidget(
              viewModel: GameAssignRoleViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameZeroNightMeet frame:
            frameWidget = GameScreenZeroNightMeetWidget(
              viewModel: GameZeroNightMeetViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayFarewellSpeech frame:
            frameWidget = GameScreenDayFarewellSpeechWidget(
              viewModel: GameDayFarewellSpeechViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDaySpeech frame:
            frameWidget = GameScreenDaySpeechWidget(
              viewModel: GameDaySpeechViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayVotingStart frame:
            frameWidget = GameScreenDayVotingStartWidget(
              viewModel: GameDayVotingStartViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayPlayerVotingSpeech frame:
            frameWidget = GameScreenDayPlayerVotingSpeechWidget(
              viewModel: GameDayPlayerVotingSpeechViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDayVoteOnPlayerLeaving frame:
            frameWidget = GameScreenDayVoteOnWidget(
              viewModel: GameDayVoteOnViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayVoteOnAllLeaving frame:
            frameWidget = GameScreenDayVoteOnAllLeavingWidget(
              viewModel: GameDayVoteOnAllLeavingViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDayPlayersVotedOut frame:
            frameWidget = GameScreenDayPlayersVotedOutWidget(
              viewModel: GameDayPlayersVotedOutViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameNightStart frame:
            frameWidget = GameScreenNightStartWidget(
              viewModel: GameNightStartViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameNightRoleAction frame:
            frameWidget = GameScreenNightRoleActionWidget(
              viewModel: GameNightRoleActionViewModel(widget.viewModel, frame),
            );
            break;

          default:
            frameWidget = Text(
              "No widget for: ${widget.viewModel.current.runtimeType.toString()}",
            );
            break;
        }

        final state = widget.viewModel.state;
        final appBarColors = widget.viewModel.getAppBarColors();

        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: appBarColors.$1,
            foregroundColor: appBarColors.$2,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: appBarColors.$3,
                ),
              ),
            ),
            title: Text(widget.viewModel.getInstructionTitle()),
            actions: [
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => widget.viewModel.moveBottom(),
                    leadingIcon: Icon(Icons.first_page),
                    child: Text("Move to beginning"),
                  ),

                  MenuItemButton(
                    onPressed: () {
                      var scores = context
                          .read<GameRepository>()
                          .calculateScores(widget.viewModel.current);

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.9,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GameScoresWidget(scores: scores),
                          ),
                        ),
                      );
                    },

                    leadingIcon: Icon(Icons.score),
                    child: Text("Calculate scores"),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.6,
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: BackupTimerWidget(
                                viewModel: BackupTimerViewModel(context.read()),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    leadingIcon: Icon(Icons.timer),
                    child: Text("Backup timer"),
                  ),
                  MenuItemButton(
                    onPressed: () async {
                      var repo = context.read<GameRepository>();
                      var messenger = ScaffoldMessenger.of(context);

                      var result = await repo.duplicate(
                        widget.viewModel.current,
                      );
                      if (result.isValue) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.asValue!.value),
                            action: SnackBarAction(
                              label: "Undo",
                              onPressed: () =>
                                  repo.undoDuplication(result.asValue!.value),
                            ),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Failed to duplicate!")),
                        );
                      }
                    },
                    leadingIcon: Icon(Icons.fork_right),
                    child: Text("Duplicate game save"),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        GameUILib.confirmDialogWithDuplicationOption(
                          context,
                          widget.viewModel.current,
                          () {
                            Navigator.of(context).pop();
                            widget.viewModel.override();
                          },
                        ),

                    leadingIcon: Icon(Icons.restore_page),
                    child: Text("Narrator override"),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        GameUILib.confirmDialogWithDuplicationOption(
                          context,
                          widget.viewModel.current,
                          () {
                            Navigator.of(context).pop();
                            widget.viewModel.penalize();
                          },
                        ),
                    leadingIcon: Icon(Icons.local_police),
                    child: Text("Penalize player"),
                  ),
                ],
                builder: (context, controller, child) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: true,
            bottom: false,
            left: true,
            right: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Expanded(child: Center(child: frameWidget)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadiusGeometry.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: BoxBorder.all(color: Colors.grey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: true,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          left: 8,
                          right: 8,
                        ),
                        child: Column(
                          spacing: 8,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => FractionallySizedBox(
                                        heightFactor: 0.7,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            spacing: 16,
                                            children: [
                                              GameResultWidget(
                                                result: state.gameResult,
                                              ),
                                              GamePlayerCountersWidget(
                                                state: widget.viewModel.state,
                                              ),
                                              Expanded(
                                                child: GamePlayerSelectorWidget(
                                                  players: widget
                                                      .viewModel
                                                      .state
                                                      .players
                                                      .map(
                                                        (p) =>
                                                            GamePlayerSelectorViewModel(
                                                              p,
                                                            ),
                                                      ),
                                                  showRoles: true,
                                                  onPress: null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: GamePlayerCountersWidget(
                                      state: widget.viewModel.state,
                                    ),
                                  ),
                                ),

                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: GameResultWidget(
                                    result: state.gameResult,
                                  ),
                                ),

                                Visibility(
                                  visible: widget.viewModel.voteOn.isNotEmpty,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius:
                                            BorderRadiusGeometry.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(widget.viewModel.voteOn),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton(
                                    onPressed: widget.viewModel.canMoveTop()
                                        ? () =>
                                              GameUILib.confirmDialogWithDuplicationOption(
                                                context,
                                                widget.viewModel.current,
                                                () => widget.viewModel.setTop(),
                                              )
                                        : null,
                                    child: Icon(Icons.vertical_align_top),
                                  ),
                                ),

                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      FilledButton(
                                        onPressed: () =>
                                            widget.viewModel.moveBackward(),
                                        child: Icon(Icons.keyboard_arrow_left),
                                      ),
                                      Text(
                                        "${widget.viewModel.currentIndex}/${widget.viewModel.frameCount}",
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            widget.viewModel.moveForward(),
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                widget.viewModel
                                                        .willMovingCommit()
                                                    ? Colors.green
                                                    : null,
                                              ),
                                        ),
                                        child: Icon(
                                          widget.viewModel.willMovingCommit()
                                              ? Icons.download_done
                                              : Icons.keyboard_arrow_right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: widget.viewModel.canMoveTop()
                                        ? () => widget.viewModel.moveTop()
                                        : null,
                                    child: Icon(Icons.last_page),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
