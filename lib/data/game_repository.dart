import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:path_provider/path_provider.dart';

enum GameError { noPrevious, noNext, frameDirty, frameNotDirty, frameInvalid }

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
    if (currentFrame.dirty) {
      return Result.error(GameError.frameDirty);
    }

    if (currentFrame.next != null) {
      return Result.value(calculateState(currentFrame.next!));
    }

    return Result.error(GameError.noNext);
  }

  Result<GameState> commitFrame(GameFrame frame) {
    if (!frame.dirty) return Result.error(GameError.frameNotDirty);
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
    return frame.dirty;
  }

  GameState calculateState(GameFrame lastFrame) {
    return GameState.calculate(lastFrame);
  }

  void _saveTree(GameFrame frame) async {
    final root = frame.findFirst();
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/${root.id}.json";
    final file = File(path);

    var structure = Map<String, dynamic>.new();
    for (final frame in root.takeAllForwards()) {
      structure[frame.id] = frame.toJson();
    }

    await file.create();
    await file.writeAsString(json.encode(structure));
  }

  Future<Result<GameFrame>> _loadTree(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    final dict = json.decode(jsonString) as Map<String, dynamic>;

    var frameMap = Map<String, GameFrame>.new();
    var playerList = List<GamePlayer>.empty(growable: true);
    GameFrame? rootFrame;

    for (final kv in dict.entries) {
      GameFrame? result;
      switch (kv.value["type"]) {
        case "GameFrameStart":
          var frame = GameFrameStart();
          rootFrame = frame;
          result = frame;
          break;

        case "GameFrameAddPlayers":
          var frame = GameFrameAddPlayers();
          final List<dynamic> nameList = kv.value["players"];
          frame.players = nameList.map((v) => v.toString()).toList();
          for (final kv in nameList.indexed) {
            playerList.add(GamePlayer(kv.$1, kv.$2, GameRole.none, true));
          }
          result = frame;
          break;

        case "GameFrameAssignRole":
          final player = playerList[kv.value["playerIndex"]];
          var frame = GameFrameAssignRole(player);
          frame.role = GameRole.values.byName(kv.value["role"]);
          result = frame;
          break;

        case "GameFrameZeroNightMeet":
          var frame = GameFrameZeroNightMeet(
            GameRole.values.byName(kv.value["roleGroup"]),
          );
          result = frame;
          break;

        case "GameFrameDaySpeech":
          final player = playerList[kv.value["playerIndex"]];
          var frame = GameFrameDaySpeech(
            player,
            kv.value["dayOpening"] as bool,
          );
          frame.putUpForVoteIndex = kv.value["putUpForVoteIndex"] as int?;
          result = frame;
          break;

        case "GameFrameDayVotingStart":
          final playerIndexes = kv.value["playerIndexes"] as List<dynamic>;
          var frame = GameFrameDayVotingStart(
            playerList.where((p) => playerIndexes.contains(p.index)).toList(),
          );
          result = frame;
          break;

        case "GameFrameDayPlayerVotingSpeech":
          final player = playerList[kv.value["playerIndex"]];
          var frame = GameFrameDayPlayerVotingSpeech(player);
          result = frame;
          break;

        case "GameFrameDayVoteOn":
          final playerIndexes = kv.value["voteIndexes"] as List<dynamic>;
          final player = playerList[kv.value["playerIndex"]];
          var frame = GameFrameDayVoteOn(player);
          frame.votes = playerList
              .where((p) => playerIndexes.contains(p.index))
              .toList();
          result = frame;
          break;

        case "GameFrameDayPlayersVotedOut":
          final playerIndexes = kv.value["playerIndexes"] as List<dynamic>;
          var frame = GameFrameDayPlayersVotedOut(
            playerList.where((p) => playerIndexes.contains(p.index)).toList(),
          );
          result = frame;
          break;

        default:
          assert(false);
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
