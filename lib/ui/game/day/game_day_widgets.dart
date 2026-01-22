import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';

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
      children: [Text(viewModel.player.seatName), Text(viewModel.player.name)],
    );
  }
}

class GameDaySpeechViewModel extends GameFrameViewModel<GameFrameDaySpeech> {
  GameDaySpeechViewModel(super.gameViewModel, super.current) {
    players = state.players.map(
      (p) => GamePlayerSelectorViewModel(
        p,
        p.alive,
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
        Text(widget.viewModel.player.seatName),
        Text(widget.viewModel.player.name),
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
          child: ListView.builder(
            itemCount: viewModel.players.length,
            itemBuilder: (context, index) =>
                Text(viewModel.players.elementAt(index).seatName),
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
    return Text(viewModel.player.seatName);
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
        Text(viewModel.playerToVoteOn.seatName),
        Text(viewModel.playerToVoteOn.name),
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
        Text("Vote on all leaving:"),
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
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.players.length,
            itemBuilder: (context, index) =>
                Text(viewModel.players.elementAt(index).seatName),
          ),
        ),
      ],
    );
  }
}
