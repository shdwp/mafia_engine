import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:path_provider/path_provider.dart';

import 'game_frame_tree.dart';

enum GameError { noPrevious, noNext, frameDirty, frameNotDirty, frameInvalid }

class GameLoadState {
  GameLoadState(this._entry);

  final Map<String, dynamic> _entry;

  T get<T>(String key) {
    return _entry[key] as T;
  }

  List<T> getList<T>(String key) {
    return (_entry[key] as List<dynamic>).map((v) => v as T).toList();
  }
}

class GameRepository {
  GameState newGame() {
    return calculateState(GameFrameStart());
  }

  Future<Result<GameState>> loadGame(String segment) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/$segment";
    final frame = await _loadTree(path);
    if (frame.isError) {
      return frame.asError!;
    } else {
      return Result.value(calculateState(frame.asValue!.value));
    }
  }

  Future<Result<Iterable<String>>> iterateSavedGames() async {
    var result = List<String>.empty(growable: true);
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        result.add(entity.uri.pathSegments.last);
      }
    }

    return Result.value(result);
  }

  Result<GameState> moveBackward(GameFrame currentFrame) {
    return currentFrame.previous != null
        ? Result.value(calculateState(currentFrame.previous!))
        : Result.error(GameError.noPrevious);
  }

  Result<GameState> moveForward(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    if (currentFrame.next != null) {
      return Result.value(calculateState(currentFrame.next!));
    }

    return Result.error(GameError.noNext);
  }

  Result<GameState> moveTop(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    final lastFrame = currentFrame.findLast();
    return Result.value(calculateState(lastFrame));
  }

  Result<GameState> commitFrame(GameFrame frame) {
    if (!frame.isDirty) return Result.error(GameError.frameNotDirty);
    if (!frame.isValid) return Result.error(GameError.frameInvalid);

    var state = calculateState(frame);
    frame.previous?.next = frame;
    frame.dirty = false;
    frame.next = state.nextFrame!;
    _saveTree(frame);
    return Result.value(state);
  }

  bool willCommitOverwriteHistory(GameFrame frame) {
    return frame.next != null;
  }

  bool shouldFrameBeCommited(GameFrame frame) {
    return frame.isDirty;
  }

  Result<GameState> penalize(GameFrame frame) {
    var newFrame = GameFrameNarratorPenalize();
    frame.previous!.next = newFrame;
    newFrame.next = frame;
    newFrame.previous = frame.previous!;
    frame.previous = newFrame;

    var state = calculateState(newFrame);
    _saveTree(newFrame);
    return Result.value(state);
  }

  GameState calculateState(GameFrame lastFrame) {
    return GameState.calculate(lastFrame);
  }

  void _saveTree(GameFrame frame) async {
    final root = frame.findFirst();
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/${root.id}.json";
    final file = File(path);

    GameFrame? currentFrame = root;
    var structure = <String, dynamic>{};
    do {
      structure[currentFrame!.id] = currentFrame.toJson();
      currentFrame = currentFrame.next;
    } while (currentFrame != null);

    await file.create();
    await file.writeAsString(json.encode(structure));
  }

  Future<Result<GameFrame>> _loadTree(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    final dict = json.decode(jsonString) as Map<String, dynamic>;

    var frameMap = <String, GameFrame>{};
    GameFrame? rootFrame;

    for (final kv in dict.entries) {
      GameFrame? result;
      final state = GameLoadState(kv.value as Map<String, dynamic>);

      switch (kv.value["type"]) {
        case "GameFrameStart":
          var frame = GameFrameStart();
          rootFrame = frame;
          result = frame;
          break;

        case "GameFrameAddPlayers":
          result = GameFrameAddPlayers.fromJson(state);
          break;

        case "GameFrameAssignRole":
          result = GameFrameAssignRole.fromJson(state);
          break;

        case "GameFrameZeroNightMeet":
          result = GameFrameZeroNightMeet.fromJson(state);
          break;

        case "GameFrameDaySpeech":
          result = GameFrameDaySpeech.fromJson(state);
          break;

        case "GameFrameDayVotingStart":
          result = GameFrameDayVotingStart.fromJson(state);
          break;

        case "GameFrameDayPlayerVotingSpeech":
          result = GameFrameDayPlayerVotingSpeech.fromJson(state);
          break;

        case "GameFrameDayVoteOnPlayerLeaving":
          result = GameFrameDayVoteOnPlayerLeaving.fromJson(state);
          break;

        case "GameFrameDayVoteOnAllLeaving":
          result = GameFrameDayVoteOnAllLeaving.fromJson(state);
          break;

        case "GameFrameDayPlayersVotedOut":
          result = GameFrameDayPlayersVotedOut.fromJson(state);
          break;

        case "GameFrameNightPriestAction":
          result = GameFrameNightRoleAction.fromJson(state);
          break;

        case "GameFrameNarratorPenalize":
          result = GameFrameNarratorPenalize.fromJson(state);
          break;

        case "GameFrameNightStart":
          result = GameFrameNightStart.fromJson(state);
          break;

        case "GameFrameNightRoleAction":
          result = GameFrameNightRoleAction.fromJson(state);
          break;

        case "GameFrameDayFarewellSpeech":
          result = GameFrameDayFarewellSpeech.fromJson(state);
          break;

        default:
          assert(false, "unknown type: ${kv.value["type"]}");
          break;
      }

      if (result != null) {
        result.id = kv.value["id"];
        result.dirty = kv.value["dirty"] as bool;
        frameMap[kv.key] = result;
      }
    }

    for (final frame in frameMap.values) {
      final String? nextString = dict[frame.id]["next"];
      if (nextString != null) {
        frame.next = frameMap[nextString];
      }

      final String? prevString = dict[frame.id]["previous"];
      if (prevString != null) {
        frame.previous = frameMap[prevString];
      }
    }

    return Result.value(rootFrame!.findLast());
  }
}
