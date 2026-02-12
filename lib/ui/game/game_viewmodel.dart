import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_frame_tree.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';

enum GameViewModelResult { ok, noFrame, confirmOverwrite }

class GameViewModel extends ChangeNotifier {
  GameViewModel({required GameRepository repository, required this.state})
    : _repository = repository {
    root = state.rootFrame;
    current = state.lastFrame;
  }

  final GameRepository _repository;

  late GameFrame root;
  late GameFrame current;
  late GameState state;

  int get currentIndex => state.frameIndex + (current.isDirty ? 1 : 0);
  int get frameCount => state.frameCount + 1;

  String getInstructionTitle() {
    switch (current) {
      case GameFrameStart _:
        return "Game hasn't started yet";
      case GameFrameAddPlayers _:
        return "Game hasn't started yet";
      case GameFrameAssignRole _:
        return "Wake up, assign role";
      case GameFrameZeroNightMeet _:
        return "Wake up players to meet";
      case GameFrameDaySpeech _:
        return "Day speech";
      case GameFrameDayVotingStart _:
        return "Voting segment starting";
      case GameFrameDayPlayerVotingSpeech _:
        return "Voting player defence speech";
      case GameFrameDayVoteOnPlayerLeaving _:
        return "Voting for player leaving";
      case GameFrameDayVoteOnAllLeaving _:
        return "Voting for both leaving";
      case GameFrameDayPlayersVotedOut _:
        return "Voted-out farewell speech";
      case GameFrameNightStart _:
        return "Everyone asleep, night starts";
      case GameFrameNightRoleAction _:
        return "Night role action";
      case GameFrameDayFarewellSpeech _:
        return "Night-kill farewell speech";
      case GameFrameNarratorStateOverride _:
        return "Narrator override";
      case GameFrameNarratorPenalize _:
        return "Narrator penalize";
      default:
        return "ERROR";
    }
  }

  void moveForward() {
    if (_repository.shouldFrameBeCommited(current)) {
      var result = _repository.commitFrame(current);
      if (result.isError) {
        return;
      }

      state = result.asValue!.value;
      current = current.next!;
      notifyListeners();
    } else {
      var result = _repository.moveForward(current);
      if (result.isError) {
        return;
      }

      state = result.asValue!.value;
      current = state.lastFrame;
      notifyListeners();
    }
  }

  bool willMovingCommit() {
    return _repository.shouldFrameBeCommited(current);
  }

  void moveTop() {
    var result = _repository.moveTop(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  bool canMoveTop() {
    return current != current.findLast();
  }

  void moveBackward() {
    var result = _repository.moveBackward(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  void setTop() {
    var result = _repository.setTop(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    current.dirty = true;
    notifyListeners();
  }

  void override() {
    var result = _repository.override(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  void penalize() {
    var result = _repository.penalize(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }
}

class GameFrameViewModel<T extends GameFrame> extends ChangeNotifier {
  GameFrameViewModel(this.gameViewModel, this.current);

  final GameViewModel gameViewModel;
  GameFrame get root => gameViewModel.root;
  final T current;
  GameState get state => gameViewModel.state;

  void setDirty() {
    current.dirty = true;
    notifyListeners();
  }
}
