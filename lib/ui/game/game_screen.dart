import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';

import 'day/game_day_widgets.dart';
import 'game_widgets.dart';
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
    return Scaffold(
      body: SafeArea(
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

            final state = widget.viewModel.state;
            return Column(
              children: [
                Expanded(child: frameWidget),
                Column(
                  children: [
                    Text(
                      "Civ: ${state.aliveCivilianCount}, maf: ${state.mafiaCount}, killer: ${state.killerCount}",
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "[${widget.viewModel.current.previous?.id} => ${widget.viewModel.current.id} ${widget.viewModel.current.isDirty} => ${widget.viewModel.current.next?.id}]",
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "[${widget.viewModel.current.runtimeType.toString()}]",
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.viewModel.overview(),
                          child: Text("Overview"),
                        ),
                        Text(
                          widget.viewModel.state.gameResult == GameResult.none
                              ? ""
                              : widget.viewModel.state.gameResult.toString(),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.viewModel.penalize(),
                          child: Text("Penalize"),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.viewModel.moveBackward(),
                          child: Text("<"),
                        ),
                        Text(
                          "${widget.viewModel.currentIndex}/${widget.viewModel.frameCount}",
                        ),
                        ElevatedButton(
                          onPressed: () => widget.viewModel.moveTop(),
                          child: Text(">>"),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.viewModel.moveForward(),
                          child: Text(">"),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GameNarratorPenalizeViewModel
    extends GameFrameViewModel<GameFrameNarratorPenalize> {
  GameNarratorPenalizeViewModel(super.gameViewModel, super.current) {
    players = state.players.map(
      (p) => GamePlayerSelectorViewModel(p, true, current.index == p.index),
    );
  }

  Iterable<GamePlayerSelectorViewModel> players = List.empty();
  String? get currentAmount =>
      (current.index != null ? state.players[current.index!].penalties : null)
          .toString();

  void select(int index) {
    current.index = index;
    setDirty();
  }

  void setPenaltyAmount(int amount) {
    current.amount = amount;
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
          Expanded(
            child: GamePlayerSelectorWidget(
              players: viewModel.players,
              onPress: (index) => viewModel.select(index),
            ),
          ),
          Text(viewModel.currentAmount ?? "No player"),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(1),
                child: Text("+1"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(2),
                child: Text("+2"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(3),
                child: Text("+3"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(4),
                child: Text("+4"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(0),
                child: Text("0"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-1),
                child: Text("-1"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-2),
                child: Text("-2"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-3),
                child: Text("-3"),
              ),
              ElevatedButton(
                onPressed: () => viewModel.setPenaltyAmount(-4),
                child: Text("-4"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
