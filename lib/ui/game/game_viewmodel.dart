import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_frame_tree.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/data/music_service.dart';

enum GameViewModelResult { ok, noFrame, confirmOverwrite }

class GameViewModel extends ChangeNotifier {
  GameViewModel({
    required GameController controller,
    required this.state,
    required GameConfigService configService,
  }) : _controller = controller,
       _configService = configService {
    _showFrame(state.lastFrame);
  }

  final GameController _controller;
  final GameConfigService _configService;

  late GameFrame root;
  late GameFrame current;
  late GameState state;
  late GameFrame _historyCurrent;
  Future<bool> Function()? confirmHistoryOverwrite;
  bool _submitting = false;

  void _showFrame(GameFrame frame) {
    _historyCurrent = frame;
    current = frame.next == null ? frame : frame.createDraft();
    state = GameState.calculate(current);
    root = state.rootFrame;
  }

  bool get _draftChanged {
    if (identical(current, _historyCurrent)) return false;
    Map<String, dynamic> data(GameFrame frame) => frame.toJson()
      ..remove('dirty');
    return jsonEncode(data(current)) != jsonEncode(data(_historyCurrent));
  }

  bool get _nicknameOnlyDraft {
    final draft = current;
    final original = _historyCurrent;
    return !identical(draft, original) &&
        draft is GameFrameAddPlayers &&
        original is GameFrameAddPlayers &&
        draft.players.length == original.players.length &&
        setEquals(draft.roles.toSet(), original.roles.toSet());
  }

  void _saveNicknameDraft() {
    if (!_draftChanged || !_nicknameOnlyDraft) return;
    _controller.saveFrameKeepingHistory(current);
    _historyCurrent = current;
  }

  void discardDraft() {
    _showFrame(_historyCurrent);
    notifyListeners();
  }

  int get currentIndex => state.frameIndex;
  int get frameCount => state.frameCount;

  String get voteOn => state.playersUpForVote.map((p) => p.seatName).join(", ");

  bool get hideTeamCounters =>
      !state.isNightPhase && _configService.hideSensitiveInfoOnDayScreen;

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
      case GameFrameCompensationImmunities _:
        return "Compensation immunities";
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

  Future<void> moveForward() async {
    if (_submitting) return;
    _submitting = true;
    try {
      final submitted = current;
      if (willMovingCommit()) {
        if (!current.isValid) return;
        if (_controller.willCommitOverwriteHistory(current)) {
          final confirmed = await confirmHistoryOverwrite?.call() ?? false;
          if (!confirmed || !identical(submitted, current)) return;
        }
        // Historical edits may not set dirty (for example, game names).
        current.dirty = true;
        final result = _controller.commitFrame(current);
        if (result.isError) return;
        _showFrame(result.asValue!.value.lastFrame);
      } else {
        // Nickname, penalty, and compensation immunity edits keep history.
        if (_draftChanged &&
            (_nicknameOnlyDraft ||
                current is GameFrameNarratorPenalize ||
                current is GameFrameCompensationImmunities)) {
          _controller.saveFrameKeepingHistory(current);
          _historyCurrent = current;
        }
        final result = _controller.moveForward(_historyCurrent);
        if (result.isError) return;
        _showFrame(result.asValue!.value.lastFrame);
      }
      notifyListeners();
    } finally {
      _submitting = false;
    }
  }

  void moveFrames(int offset) {
    if (offset == 0 || (offset > 0 && willMovingCommit())) return;

    if (offset > 0) _saveNicknameDraft();

    var target = _historyCurrent;
    for (var remaining = offset.abs(); remaining > 0; remaining--) {
      final next = offset < 0 ? target.previous : target.next;
      if (next == null) break;
      target = next;
    }
    if (target == _historyCurrent) return;

    _showFrame(target);
    notifyListeners();
  }

  bool willMovingCommit() {
    if (!identical(current, _historyCurrent)) {
      return _draftChanged &&
          !_nicknameOnlyDraft &&
          current is! GameFrameNarratorPenalize &&
          current is! GameFrameCompensationImmunities;
    }
    return _controller.shouldFrameBeCommited(current);
  }

  void moveTop() {
    _saveNicknameDraft();
    var result = _controller.moveTop(_historyCurrent);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
    notifyListeners();
  }

  void moveBottom() {
    var result = _controller.moveBottom(_historyCurrent);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
    notifyListeners();
  }

  bool canMoveTop() {
    return _historyCurrent.next != null;
  }

  void moveBackward() {
    var result = _controller.moveBackward(_historyCurrent);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
    notifyListeners();
  }

  void setTop() {
    if (!identical(current, _historyCurrent)) {
      current.previous?.next = current;
    }
    var result = _controller.setTop(current);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
    current.dirty = true;
    notifyListeners();
  }

  void override() {
    var result = _controller.override(_historyCurrent);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
    notifyListeners();
  }

  void penalize() {
    var result = _controller.penalize(_historyCurrent);
    if (result.isError) {
      return;
    }

    _showFrame(result.asValue!.value.lastFrame);
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
