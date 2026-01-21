import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';

enum GameViewModelResult { ok, noFrame, confirmOverwrite }

class GameViewModel extends ChangeNotifier {
  GameViewModel({required GameRepository repository, required this.lastState})
    : _repository = repository {
    rootFrame = lastState.rootFrame;
    currentFrame = lastState.lastFrame;
  }

  final GameRepository _repository;

  late GameFrame rootFrame;
  late GameFrame currentFrame;
  late GameState lastState;

  int get currentIndex => lastState.frameIndex + (currentFrame.dirty ? 1 : 0);
  int get frameCount => lastState.frameCount + 1;

  void moveForward() {
    if (_repository.shouldFrameBeCommited(currentFrame)) {
      var result = _repository.commitFrame(currentFrame);
      if (result.isError) {
        return;
      }

      lastState = result.asValue!.value;
      currentFrame = lastState.nextFrame!;
      notifyListeners();
    } else {
      var result = _repository.moveForward(currentFrame);
      if (result.isError) {
        return;
      }

      lastState = result.asValue!.value;
      currentFrame = lastState.lastFrame;
      notifyListeners();
    }
  }

  void moveBackward() {
    var result = _repository.moveBackward(currentFrame);
    if (result.isError) {
      return;
    }

    lastState = result.asValue!.value;
    currentFrame = lastState.lastFrame;
    notifyListeners();
  }
}

class GameFrameViewModel<T extends GameFrame> extends ChangeNotifier {
  GameFrameViewModel(this.gameViewModel, this.lastFrame);

  final GameViewModel gameViewModel;
  GameFrame get rootFrame => gameViewModel.rootFrame;
  final T lastFrame;
  GameState get lastState => gameViewModel.lastState;

  void _setDirty() {
    lastFrame.dirty = true;
    notifyListeners();
  }
}

class GameAddPlayersViewModel extends GameFrameViewModel<GameFrameAddPlayers> {
  GameAddPlayersViewModel(super.gameViewModel, super.lastFrame);

  void addEmptyPlayer() {
    lastFrame.players.add("Empty");
    _setDirty();
  }

  void movePlayerUp(int index) {
    if (index <= 0) return;
    final value = lastFrame.players.removeAt(index);
    lastFrame.players.insert(index - 1, value);
    _setDirty();
  }

  void movePlayerDown(int index) {
    if (index >= lastFrame.players.length - 1) return;
    final value = lastFrame.players.removeAt(index);
    lastFrame.players.insert(index + 1, value);
    _setDirty();
  }
}

class GameAssignRoleViewModel extends GameFrameViewModel<GameFrameAssignRole> {
  GameAssignRoleViewModel(super.gameViewModel, super.lastFrame);

  String get name => lastFrame.player.name;
  String get seat => lastFrame.player.seatName;
  String get role => "${lastFrame.role}";

  void assign(GameRole role) {
    lastFrame.role = role;
    _setDirty();
    gameViewModel.moveForward();
  }
}

class GameZeroNightMeetViewModel
    extends GameFrameViewModel<GameFrameZeroNightMeet> {
  GameZeroNightMeetViewModel(super.gameViewModel, super.lastFrame);

  String get role => lastFrame.roleGroup.toString();
  String get seats =>
      ""; // lastState.players .map((p) => p.seatName).join(", ");
}

class GameDaySpeechViewModel extends GameFrameViewModel<GameFrameDaySpeech> {
  GameDaySpeechViewModel(super.gameViewModel, super.lastFrame) {
    players = lastState.players.map(
      (p) => GamePlayerSelectorViewModel(
        p,
        p.alive,
        p.index == lastFrame.putUpForVoteIndex,
      ),
    );
  }

  String get name => lastFrame.player.name;
  String get seat => lastFrame.player.seatName;
  Iterable<GamePlayerSelectorViewModel> players = List.empty();

  void selectForVoting(int index) {
    if (lastFrame.putUpForVoteIndex == index) {
      lastFrame.putUpForVoteIndex = null;
    } else {
      lastFrame.putUpForVoteIndex = index;
    }
    _setDirty();
  }
}

class GameDayVotingStartViewModel
    extends GameFrameViewModel<GameFrameDayVotingStart> {
  GameDayVotingStartViewModel(super.gameViewModel, super.lastFrame);
}

class GameDayPlayerVotingSpeechViewModel
    extends GameFrameViewModel<GameFrameDayPlayerVotingSpeech> {
  GameDayPlayerVotingSpeechViewModel(super.gameViewModel, super.lastFrame);
}

class GameDayVoteOnViewModel extends GameFrameViewModel<GameFrameDayVoteOn> {
  GameDayVoteOnViewModel(super.gameViewModel, super.lastFrame) {
    players = lastState.players.map(
      (p) =>
          GamePlayerSelectorViewModel(p, p.alive, lastFrame.votes.contains(p)),
    );
  }

  late Iterable<GamePlayerSelectorViewModel> players = List.empty();

  void selectVoting(int index) {
    final player = lastState.players.elementAt(index);
    if (lastFrame.votes.contains(player)) {
      lastFrame.votes.remove(player);
    } else {
      lastFrame.votes.add(player);
    }
    _setDirty();
  }
}

class GameDayPlayersVotedOutViewModel
    extends GameFrameViewModel<GameFrameDayPlayersVotedOut> {
  GameDayPlayersVotedOutViewModel(super.gameViewModel, super.lastFrame);
}
