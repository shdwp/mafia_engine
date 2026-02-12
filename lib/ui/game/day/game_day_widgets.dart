import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:provider/provider.dart';

import '../game_viewmodel.dart';
import '../game_widgets.dart';

class GameDayFarewellSpeechViewModel
    extends GameFrameViewModel<GameFrameDayFarewellSpeech> {
  GameDayFarewellSpeechViewModel(super.gameViewModel, super.lastFrame);

  GamePlayer get player => state.players[current.index];
}

class GameScreenDayFarewellSpeechWidget extends StatelessWidget {
  const GameScreenDayFarewellSpeechWidget({super.key, required this.viewModel});
  final GameDayFarewellSpeechViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            GamePlayerBadgeWidget(player: viewModel.player),
            GameTimerWidget(
              timeInSeconds: context.read<GameConfigService>().farewellTimer,
            ),
          ],
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
        p.index == current.putUpForVoteIndex ||
            (p.alive && !state.playersUpForVote.contains(p)),
        p.index == current.putUpForVoteIndex,
      ),
    );
  }

  GamePlayer get player => state.players[current.index];
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            GamePlayerBadgeWidget(player: widget.viewModel.player),
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
      children: [
        Row(
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
        p.alive && !alreadyVotedMap.contains(p.index),
        current.votes.contains(p.index),
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
        p.alive && !current.playersToVoteFor.contains(p.index),
        current.votes.contains(p.index),
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
      children: [
        GameTimerWidget(
          timeInSeconds: context.read<GameConfigService>().farewellTimer,
        ),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 18),
            itemCount: viewModel.players.length,
            itemBuilder: (context, index) => Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GamePlayerBadgeWidget(
                  player: viewModel.players.elementAt(index),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
