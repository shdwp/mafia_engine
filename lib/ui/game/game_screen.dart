import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';

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
            switch (widget.viewModel.currentFrame) {
              case GameFrameAddPlayers frame:
                frameWidget = _GameScreenAddPlayersWidget(
                  viewModel: GameAddPlayersViewModel(widget.viewModel, frame),
                );
                break;
              case GameFrameAssignRole frame:
                frameWidget = _GameScreenAssignRoleWidget(
                  viewModel: GameAssignRoleViewModel(widget.viewModel, frame),
                );
                break;

              case GameFrameZeroNightMeet frame:
                frameWidget = _GameScreenZeroNightMeetWidget(
                  viewModel: GameZeroNightMeetViewModel(
                    widget.viewModel,
                    frame,
                  ),
                );
                break;

              case GameFrameDaySpeech frame:
                frameWidget = _GameScreenDaySpeechWidget(
                  viewModel: GameDaySpeechViewModel(widget.viewModel, frame),
                );
                break;

              case GameFrameDayVotingStart frame:
                frameWidget = _GameScreenDayVotingStartWidget(
                  viewModel: GameDayVotingStartViewModel(
                    widget.viewModel,
                    frame,
                  ),
                );
                break;

              case GameFrameDayPlayerVotingSpeech frame:
                frameWidget = _GameScreenDayPlayerVotingSpeechWidget(
                  viewModel: GameDayPlayerVotingSpeechViewModel(
                    widget.viewModel,
                    frame,
                  ),
                );
                break;

              case GameFrameDayVoteOn frame:
                frameWidget = _GameScreenDayVoteOnWidget(
                  viewModel: GameDayVoteOnViewModel(widget.viewModel, frame),
                );
                break;

              case GameFrameDayPlayersVotedOut frame:
                frameWidget = _GameScreenDayPlayersVotedOutWidget(
                  viewModel: GameDayPlayersVotedOutViewModel(
                    widget.viewModel,
                    frame,
                  ),
                );
                break;

              default:
                frameWidget = Text(
                  "No widget for: ${widget.viewModel.currentFrame.runtimeType.toString()}",
                );
                break;
            }

            final state = widget.viewModel.lastState;
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
                        ElevatedButton(
                          onPressed: () => widget.viewModel.moveBackward(),
                          child: Text("<"),
                        ),
                        Text(
                          "${widget.viewModel.currentIndex}/${widget.viewModel.frameCount}",
                        ),
                        Text(
                          "[${widget.viewModel.currentFrame.previous?.id} => ${widget.viewModel.currentFrame.id} ${widget.viewModel.currentFrame.dirty} => ${widget.viewModel.currentFrame.next?.id}]",
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

class _GameScreenAddPlayersWidget extends StatefulWidget {
  const _GameScreenAddPlayersWidget({super.key, required this.viewModel});
  final GameAddPlayersViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenInputPlayersState();
}

class _GameScreenInputPlayersState extends State<_GameScreenAddPlayersWidget> {
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
                    Text(widget.viewModel.lastFrame.players[index]),
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
              itemCount: widget.viewModel.lastFrame.players.length,
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

class _GameScreenAssignRoleWidget extends StatefulWidget {
  const _GameScreenAssignRoleWidget({super.key, required this.viewModel});
  final GameAssignRoleViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenAssignRoleState();
}

class _GameScreenAssignRoleState extends State<_GameScreenAssignRoleWidget> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) => Column(
        children: [
          Text(widget.viewModel.seat),
          Text(widget.viewModel.name),
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

class _GameScreenZeroNightMeetWidget extends StatefulWidget {
  const _GameScreenZeroNightMeetWidget({super.key, required this.viewModel});
  final GameZeroNightMeetViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenZeroNightMeetState();
}

class _GameScreenZeroNightMeetState
    extends State<_GameScreenZeroNightMeetWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Text(widget.viewModel.role), Text(widget.viewModel.seats)],
    );
  }
}

class _GameScreenDaySpeechWidget extends StatefulWidget {
  const _GameScreenDaySpeechWidget({super.key, required this.viewModel});
  final GameDaySpeechViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenDaySpeechState();
}

class _GameScreenDaySpeechState extends State<_GameScreenDaySpeechWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.viewModel.seat),
        Text(widget.viewModel.name),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: widget.viewModel.players,
              onPress: (index) => widget.viewModel.selectForVoting(index),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameScreenDayVotingStartWidget extends StatelessWidget {
  const _GameScreenDayVotingStartWidget({super.key, required this.viewModel});
  final GameDayVotingStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: viewModel.lastFrame.players.length,
        itemBuilder: (context, index) =>
            Text(viewModel.lastFrame.players.elementAt(index).seatName),
      ),
    );
  }
}

class _GameScreenDayPlayerVotingSpeechWidget extends StatelessWidget {
  final GameDayPlayerVotingSpeechViewModel viewModel;

  const _GameScreenDayPlayerVotingSpeechWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Text(viewModel.lastFrame.player.seatName);
  }
}

class _GameScreenDayVoteOnWidget extends StatelessWidget {
  final GameDayVoteOnViewModel viewModel;

  const _GameScreenDayVoteOnWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(viewModel.lastFrame.playerToVoteFor.seatName),
        Text(viewModel.lastFrame.playerToVoteFor.name),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: viewModel.players,
              onPress: (index) => viewModel.selectVoting(index),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameScreenDayPlayersVotedOutWidget extends StatelessWidget {
  const _GameScreenDayPlayersVotedOutWidget({
    super.key,
    required this.viewModel,
  });
  final GameDayPlayersVotedOutViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemBuilder: (context, index) =>
            Text(viewModel.lastFrame.playersVotedOut.elementAt(index).seatName),
      ),
    );
  }
}
