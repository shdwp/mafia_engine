import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
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

class _GameScreenGameState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: BottomSheet(
        onClosing: () {},
        animationController: AnimationController(
          vsync: this,
          duration: Duration(seconds: 1),
        ),
        enableDrag: true,
        showDragHandle: true,
        builder: (context) {
          return IntrinsicHeight(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) {
                final state = widget.viewModel.state;
                return Column(
                  spacing: 4,
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
                                heightFactor: 0.8,
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 16,
                                        children: [
                                          FilledButton(
                                            onPressed: () =>
                                                GameUILib.confirmDialogWithDuplicationOption(
                                                  context,
                                                  widget.viewModel.current,
                                                  () => widget.viewModel
                                                      .override(),
                                                ),
                                            child: Text("Override"),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                GameUILib.confirmDialogWithDuplicationOption(
                                                  context,
                                                  widget.viewModel.current,
                                                  () => widget.viewModel
                                                      .penalize(),
                                                ),
                                            child: Text("Penalize"),
                                          ),
                                        ],
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
                          child: GameResultWidget(result: state.gameResult),
                        ),

                        Visibility(
                          visible: widget.viewModel.voteOn.isNotEmpty,
                          child: Container(
                            alignment: Alignment.centerRight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadiusGeometry.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(widget.viewModel.voteOn),
                              ),
                            ),
                          ),
                        ),

                        /*
                      Text(
                        "${widget.viewModel.current.previous?.id}< C${widget.viewModel.current.id} S${widget.viewModel.state.lastFrame.id} >${widget.viewModel.current.next?.id}",
                      ),
            					*/
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
                            child: Text("TOP"),
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
                                child: Text("<"),
                              ),
                              Text(
                                "${widget.viewModel.currentIndex}/${widget.viewModel.frameCount}",
                              ),
                              FilledButton(
                                onPressed: () => widget.viewModel.moveForward(),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    widget.viewModel.willMovingCommit()
                                        ? Colors.redAccent
                                        : null,
                                  ),
                                ),
                                child: Text(">"),
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
                            child: Text(">>"),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 16,
                      children: [
                        SizedBox(
                          height: 400,
                          child: GamePlayerSelectorWidget(
                            players: widget.viewModel.state.players.map(
                              (p) => GamePlayerSelectorViewModel(p),
                            ),
                            showRoles: true,
                            onPress: null,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            FilledButton(
                              onPressed: () =>
                                  GameUILib.confirmDialogWithDuplicationOption(
                                    context,
                                    widget.viewModel.current,
                                    () => widget.viewModel.override(),
                                  ),
                              child: Text("Override"),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  GameUILib.confirmDialogWithDuplicationOption(
                                    context,
                                    widget.viewModel.current,
                                    () => widget.viewModel.penalize(),
                                  ),
                              child: Text("Penalize"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) =>
              Text(widget.viewModel.getInstructionTitle()),
        ),
        actions: [
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: () async {
                  var repo = context.read<GameRepository>();
                  var messenger = ScaffoldMessenger.of(context);

                  var result = await repo.duplicate(widget.viewModel.current);
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
                child: Row(
                  children: [
                    Icon(Icons.fork_right),
                    Text("Duplicate game save"),
                  ],
                ),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) {
            Widget frameWidget = Text("error");
            switch (widget.viewModel.current) {
              case GameFrameNarratorPenalize frame:
                frameWidget = GameScreenNarratorPenalizeWidget(
                  viewModel: GameNarratorPenalizeViewModel(
                    widget.viewModel,
                    frame,
                  ),
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
                  viewModel: GameZeroNightMeetViewModel(
                    widget.viewModel,
                    frame,
                  ),
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
                  viewModel: GameDayVotingStartViewModel(
                    widget.viewModel,
                    frame,
                  ),
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
                  viewModel: GameNightRoleActionViewModel(
                    widget.viewModel,
                    frame,
                  ),
                );
                break;

              default:
                frameWidget = Text(
                  "No widget for: ${widget.viewModel.current.runtimeType.toString()}",
                );
                break;
            }

            return Center(child: frameWidget);
          },
        ),
      ),
    );
  }
}
