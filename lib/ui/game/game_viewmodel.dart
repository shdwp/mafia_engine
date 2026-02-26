import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_frame_tree.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/data/music_service.dart';

enum GameViewModelResult { ok, noFrame, confirmOverwrite }

class GameViewModel extends ChangeNotifier {
  GameViewModel({required GameController controller, required this.state})
    : _controller = controller {
    root = state.rootFrame;
    current = state.lastFrame;
  }

  final GameController _controller;

  late GameFrame root;
  late GameFrame current;
  late GameState state;

  int get currentIndex => state.frameIndex;
  int get frameCount => state.frameCount;

  String get voteOn => state.playersUpForVote.map((p) => p.seatName).join(", ");

  MusicPlaylist get playlistForCurrentState =>
      _controller.playlistForFrame(current);

  String getInstructionTitle() {
    switch (current) {
      case GameFrameStart _:
        return "Game hasn't started yet";
      case GameFrameAddPlayers _:
        return "Adding players";
      case GameFrameZeroNightStart _:
        return "Night starts";
      case GameFrameAssignRole _:
        return "Assigning roles";
      case GameFrameZeroNightMeet frame:
        switch (frame.roleGroup) {
          case GameRole.mafia:
            return "Mafia meets each other";
          case GameRole.sheriff:
            return "Sheriff shows themselves";
          case GameRole.doctor:
            return "Doctor shows themselves";
          case GameRole.killer:
            return "Killer shows themselves";
          default:
            return "ERROR";
        }
      case GameFrameDayStart _:
        return "Day starts";
      case GameFrameDaySpeech _:
        return "Day speech";
      case GameFrameDayVotingStart _:
        return "Voting starting";
      case GameFrameDayPlayerVotingSpeech _:
        return "Defence speech";
      case GameFrameDayVoteOnPlayerLeaving _:
        return "Voting for player to leave";
      case GameFrameDayVoteOnAllLeaving _:
        return "Voting for all leaving";
      case GameFrameDayPlayersVotedOut _:
        return "Farewell speech";
      case GameFrameNightStart _:
        return "Night starts";
      case GameFrameNightRoleAction frame:
        switch (frame.role) {
          case GameRole.mafia:
            return "Mafia selects who to kill:";
          case GameRole.don:
            return "Don selects check:";
          case GameRole.priest:
            return "Priest selects block:";
          case GameRole.sheriff:
            return "Sheriff checks check:";
          case GameRole.doctor:
            return "Doctor selects save:";
          case GameRole.killer:
            return "Killer selects who to kill:";
          default:
            return "ERROR";
        }
      case GameFrameDayFarewellSpeech _:
        return "Farewell speech";
      case GameFrameNarratorStateOverride _:
        return "Narrator override";
      case GameFrameNarratorPenalize _:
        return "Narrator penalize";
      default:
        return "ERROR";
    }
  }

  (SystemUiOverlayStyle, Color, List<Color>) getAppBarColors() {
    if (state.isNightPhase) {
      return (
        SystemUiOverlayStyle.light,
        Colors.white,
        [Colors.black, Color.fromARGB(255, 7, 42, 108)],
      );
    } else {
      return (
        SystemUiOverlayStyle.dark,
        Colors.black,
        [Colors.white, Color.fromARGB(255, 252, 229, 112)],
      );
    }
  }

  void moveForward() {
    if (_controller.shouldFrameBeCommited(current)) {
      var result = _controller.commitFrame(current);
      if (result.isError) {
        return;
      }

      state = result.asValue!.value;
      current = current.next!;
      notifyListeners();
    } else {
      var result = _controller.moveForward(current);
      if (result.isError) {
        return;
      }

      state = result.asValue!.value;
      current = state.lastFrame;
      notifyListeners();
    }
  }

  bool willMovingCommit() {
    return _controller.shouldFrameBeCommited(current);
  }

  void moveTop() {
    var result = _controller.moveTop(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  void moveBottom() {
    var result = _controller.moveBottom(current);
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
    var result = _controller.moveBackward(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  void setTop() {
    var result = _controller.setTop(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    current.dirty = true;
    notifyListeners();
  }

  void override() {
    var result = _controller.override(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
  }

  void penalize() {
    var result = _controller.penalize(current);
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
