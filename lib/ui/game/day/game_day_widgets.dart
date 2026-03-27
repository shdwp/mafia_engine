import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';
import '../game_widgets.dart';

class GameDayFarewellSpeechViewModel
    extends GameFrameViewModel<GameFrameDayFarewellSpeech> {
  GameDayFarewellSpeechViewModel(super.gameViewModel, super.lastFrame);

  Iterable<GamePlayer> get players =>
      current.playersKilled.map((i) => state.players[i]);

  Iterable<GamePlayer> get allPlayers => state.players;

  bool get shouldShowGuess => current.firstNight;

  Iterable<GamePlayer> get firstGuessPlayers =>
      state.players.where((p) => current.playersKilled.contains(p.index));

  int? votesFor(int playerIndex) {
    final voteMap = state.voteMap;
    if (voteMap.containsKey(-1)) return voteMap[-1]!.length;
    return voteMap[playerIndex]?.length;
  }

  bool isGuessSelected(int playerIndex, int guessIndex) {
    return current.firstNightGuesses[playerIndex].contains(guessIndex);
  }

  void toggleGuess(int playerIndex, int guessIndex) {
    if (current.firstNightGuesses[playerIndex].contains(guessIndex)) {
      current.firstNightGuesses[playerIndex].remove(guessIndex);
    } else {
      current.firstNightGuesses[playerIndex].add(guessIndex);
    }

    setDirty();
  }
}

class GameScreenDayFarewellSpeechWidget extends StatelessWidget {
  const GameScreenDayFarewellSpeechWidget({super.key, required this.viewModel});
  final GameDayFarewellSpeechViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().farewellTimer,
        ),

        ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) => Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => Column(
                children: [
                  GamePlayerBadgeWidget(
                    player: viewModel.players.elementAt(index),
                  ),
                  if (viewModel.votesFor(
                        viewModel.players.elementAt(index).index,
                      )
                      case final votes?)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadiusGeometry.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Votes: $votes',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

                  if (viewModel.shouldShowGuess)
                    SizedBox(
                      height: 240,
                      child: GamePlayerSelectorWidget(
                        crossAxisCount: 6,
                        fontSize: 12,
                        players: viewModel.allPlayers.map(
                          (p) => GamePlayerSelectorViewModel(
                            p,
                            available: true,
                            highlighted:
                                p.index ==
                                viewModel.players.elementAt(index).index,
                            selected: viewModel.isGuessSelected(index, p.index),
                          ),
                        ),
                        onPress: (selectedIndex) =>
                            viewModel.toggleGuess(index, selectedIndex),
                      ),
                    ),
                ],
              ),
              separatorBuilder: (context, index) => Divider(),
              itemCount: viewModel.players.length,
            ),
          ),
        ),
      ],
    );
  }
}

class GameDaySpeechViewModel extends GameFrameViewModel<GameFrameDaySpeech> {
  GameDaySpeechViewModel(super.gameViewModel, super.current) {
    players = state.players.map(
      (p) => GamePlayerSelectorViewModel(
        p,
        available:
            p.index == current.putUpForVoteIndex ||
            (p.alive && !state.playersUpForVote.contains(p)),
        selected: p.index == current.putUpForVoteIndex,
        highlighted: p.index == current.index,
      ),
    );
  }

  GamePlayer get player => state.players[current.index];

  (GameStateDayNextStage, GamePlayer?) get nextStage =>
      GameState.calculateNextDaySegment(current, state);

  Iterable<GamePlayerSelectorViewModel> players = List.empty();

  void selectForVoting(int index) {
    if (current.putUpForVoteIndex == index) {
      current.putUpForVoteIndex = null;
    } else {
      current.putUpForVoteIndex = index;
    }
    setDirty();
  }
}

class GameScreenDaySpeechWidget extends StatefulWidget {
  const GameScreenDaySpeechWidget({super.key, required this.viewModel});
  final GameDaySpeechViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenDaySpeechState();
}

class _GameScreenDaySpeechState extends State<GameScreenDaySpeechWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GamePlayerBadgeWidget(player: widget.viewModel.player),
                Icon(Icons.keyboard_double_arrow_right),
                switch (widget.viewModel.nextStage) {
                  (GameStateDayNextStage.playerSpeech, final player?) =>
                    GamePlayerBadgeWidget(player: player, fontSize: 12),
                  (GameStateDayNextStage.night, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadiusGeometry.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Night',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  (GameStateDayNextStage.voting, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.lightGreen,
                      borderRadius: BorderRadiusGeometry.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Voting',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  _ => SizedBox.shrink(),
                },
              ],
            ),
            GameTimerWidget(
              timeInSeconds: context.read<GameConfigService>().speechTimer,
            ),
          ],
        ),
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

class GameDayVotingStartViewModel
    extends GameFrameViewModel<GameFrameDayVotingStart> {
  GameDayVotingStartViewModel(super.gameViewModel, super.current);

  Iterable<GamePlayer> get players =>
      current.indexes.map((i) => state.players[i]);
}

class GameScreenDayVotingStartWidget extends StatelessWidget {
  const GameScreenDayVotingStartWidget({super.key, required this.viewModel});
  final GameDayVotingStartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 18),
            itemCount: viewModel.players.length,
            itemBuilder: (context, index) => Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GamePlayerBadgeWidget(
                    player: viewModel.players.elementAt(index),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GameDayPlayerVotingSpeechViewModel
    extends GameFrameViewModel<GameFrameDayPlayerVotingSpeech> {
  GameDayPlayerVotingSpeechViewModel(super.gameViewModel, super.lastFrame);

  GamePlayer get player => state.players[current.index];
}

class GameScreenDayPlayerVotingSpeechWidget extends StatelessWidget {
  final GameDayPlayerVotingSpeechViewModel viewModel;

  const GameScreenDayPlayerVotingSpeechWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            GamePlayerBadgeWidget(player: viewModel.player),
            GameTimerWidget(
              timeInSeconds: context.read<GameConfigService>().voteDefenseTimer,
            ),
          ],
        ),
      ],
    );
  }
}

class GameDayVoteOnViewModel
    extends GameFrameViewModel<GameFrameDayVoteOnPlayerLeaving> {
  GameDayVoteOnViewModel(super.gameViewModel, super.current) {
    final alreadyVotedMap = state.voteMap.entries.fold(
      List<int>.empty(growable: true),
      (list, kv) {
        if (kv.key != current.playerToVoteFor) list.addAll(kv.value);
        return list;
      },
    );
    votingPlayers = state.players.map((p) {
      return GamePlayerSelectorViewModel(
        p,
        available: p.alive && !alreadyVotedMap.contains(p.index),
        selected: current.votes.contains(p.index),
        highlighted: p.index == current.playerToVoteFor,
      );
    });

    playerToVoteOn = state.players[current.playerToVoteFor];
  }

  late GamePlayer playerToVoteOn;
  late Iterable<GamePlayerSelectorViewModel> votingPlayers = List.empty();

  void selectVoting(int index) {
    final player = state.players.elementAt(index);
    if (current.votes.contains(player.index)) {
      current.votes.remove(player.index);
    } else {
      current.votes.add(player.index);
    }
    setDirty();
  }
}

class GameScreenDayVoteOnWidget extends StatelessWidget {
  final GameDayVoteOnViewModel viewModel;

  const GameScreenDayVoteOnWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GamePlayerBadgeWidget(player: viewModel.playerToVoteOn),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: viewModel.votingPlayers,
              onPress: (index) => viewModel.selectVoting(index),
            ),
          ),
        ),
      ],
    );
  }
}

class GameDayVoteOnAllLeavingViewModel
    extends GameFrameViewModel<GameFrameDayVoteOnAllLeaving> {
  GameDayVoteOnAllLeavingViewModel(super.gameViewModel, super.current) {
    votingPlayers = state.players.map((p) {
      return GamePlayerSelectorViewModel(
        p,
        available: p.alive && !current.playersToVoteFor.contains(p.index),
        selected: current.votes.contains(p.index),
        highlighted: current.playersToVoteFor.contains(p.index),
      );
    });
  }

  late Iterable<GamePlayerSelectorViewModel> votingPlayers = List.empty();

  void selectVoting(int index) {
    final player = state.players.elementAt(index);
    if (current.votes.contains(player.index)) {
      current.votes.remove(player.index);
    } else {
      current.votes.add(player.index);
    }
    setDirty();
  }
}

class GameScreenDayVoteOnAllLeavingWidget extends StatelessWidget {
  const GameScreenDayVoteOnAllLeavingWidget({
    super.key,
    required this.viewModel,
  });
  final GameDayVoteOnAllLeavingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) => GamePlayerSelectorWidget(
              players: viewModel.votingPlayers,
              onPress: (index) => viewModel.selectVoting(index),
            ),
          ),
        ),
      ],
    );
  }
}

class GameDayPlayersVotedOutViewModel
    extends GameFrameViewModel<GameFrameDayPlayersVotedOut> {
  GameDayPlayersVotedOutViewModel(super.gameViewModel, super.lastFrame);

  Iterable<GamePlayer> get players =>
      state.players.where((p) => current.playersVotedOut.contains(p.index));

  int? votesFor(int playerIndex) {
    final voteMap = state.voteMap;
    if (voteMap.containsKey(-1)) return voteMap[-1]!.length;
    return voteMap[playerIndex]?.length;
  }
}

class GameScreenDayPlayersVotedOutWidget extends StatelessWidget {
  const GameScreenDayPlayersVotedOutWidget({
    super.key,
    required this.viewModel,
  });
  final GameDayPlayersVotedOutViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().farewellTimer,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: viewModel.players.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) => Column(
              children: [
                GamePlayerBadgeWidget(
                  player: viewModel.players.elementAt(index),
                ),
                if (viewModel.votesFor(
                      viewModel.players.elementAt(index).index,
                    )
                    case final votes?)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadiusGeometry.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Votes: $votes',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
