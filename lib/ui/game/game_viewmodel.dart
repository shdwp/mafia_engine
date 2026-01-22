import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mafia_engine/data/game_frame.dart';
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

  void moveForward() {
    if (_repository.shouldFrameBeCommited(current)) {
      var result = _repository.commitFrame(current);
      if (result.isError) {
        return;
      }

      state = result.asValue!.value;
      current = state.nextFrame!;
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

  void moveTop() {
    var result = _repository.moveTop(current);
    if (result.isError) {
      return;
    }

    state = result.asValue!.value;
    current = state.lastFrame;
    notifyListeners();
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

  void overview() {}

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
