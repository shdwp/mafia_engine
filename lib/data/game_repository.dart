import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:path_provider/path_provider.dart';

import 'game_frame_tree.dart';

enum GameError { noPrevious, noNext, frameDirty, frameNotDirty, frameInvalid }

class GameLoadState {
  final Map<String, dynamic> _entry;

  GameLoadState(this._entry);

  T get<T>(String key) {
    return _entry[key] as T;
  }

  List<T> getList<T>(String key) {
    return (_entry[key] as List<dynamic>).map((v) => v as T).toList();
  }
}

class GameSaveFile {
  final String name;
  final String path;
  final DateTime modifiedDate;

  GameSaveFile(this.name, this.modifiedDate, this.path);
}

class GameRepository {
  final List<String> _playerNames = [];

  GameRepository() {
    _loadPlayerNames().then(
      (value) =>
          value.isValue ? _playerNames.addAll(value.asValue!.value) : null,
    );
  }

  Iterable<String> suggestPlayerNames(String input) {
    var result = <String>[];
    if (input.length < 3) return result;

    for (final name in _playerNames) {
      if (name.contains(input.trim())) result.add(name.trim());
    }

    return result;
  }

  void commitPlayerNames(Iterable<String> names) {
    for (final name in names) {
      if (name.trim().isEmpty) continue;
      if (!_playerNames.contains(name.trim())) _playerNames.add(name.trim());
    }
    _savePlayerNames(_playerNames);
  }

  GameState newGame() {
    return calculateState(GameFrameStart());
  }

  Future<Result<String>> duplicate(GameFrame frame) async {
    var root = frame.findFirst() as GameFrameStart;
    var gameName = root.gameName;
    var newGameName = duplicatedSaveGameName(root);

    root.gameName = newGameName;
    await _saveTree(frame);
    root.gameName = gameName;
    return Result.value(newGameName);
  }

  Future undoDuplication(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/games/$name.json";
    final file = File(path);
    Directory("${directory.path}/gamesBackup/").create(recursive: true);
    await file.copy("${directory.path}/gamesBackup/$name.json");
    await file.delete();
  }

  Future<Result<GameState>> loadGame(String path) async {
    final frame = await _loadTree(path);
    if (frame.isError) {
      return frame.asError!;
    } else {
      return Result.value(calculateState(frame.asValue!.value));
    }
  }

  Future<Result<Iterable<GameSaveFile>>> iterateSavedGames() async {
    var result = List<GameSaveFile>.empty(growable: true);
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory("${directory.path}/games/");
    await for (final entity in dir.list()) {
      if (entity is File && entity.uri.pathSegments.last.endsWith(".json")) {
        result.add(
          GameSaveFile(
            entity.uri.pathSegments.last,
            await entity.lastModified(),
            entity.path,
          ),
        );
      }
    }

    result.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
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

  Result<GameState> setTop(GameFrame currentFrame) {
    currentFrame.next = null;
    final lastFrame = currentFrame.findLast();
    return Result.value(calculateState(lastFrame));
  }

  Result<GameState> commitFrame(GameFrame frame) {
    if (!frame.isDirty) return Result.error(GameError.frameNotDirty);
    if (!frame.isValid) return Result.error(GameError.frameInvalid);

    if (frame is GameFrameAddPlayers) {
      commitPlayerNames(frame.players);
    }

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

  Result<GameState> override(GameFrame frame) {
    var state = calculateState(frame);
    var newFrame = GameFrameNarratorStateOverride(
      GameFrameNarratorStateOverrideType.dayStart,
      state.players.map((p) {
        return (p.name, p.role, p.alive, p.penalties);
      }).toList(),
    );
    frame.previous!.next = newFrame;
    newFrame.previous = frame.previous!;
    frame.previous = newFrame;

    var newState = calculateState(newFrame);
    _saveTree(newFrame);
    return Result.value(newState);
  }

  GameState calculateState(GameFrame lastFrame) {
    return GameState.calculate(lastFrame);
  }

  void _savePlayerNames(Iterable<String> names) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/names/names.json";
    final file = File(path);

    await file.create(recursive: true);
    await file.writeAsString(json.encode(names));
  }

  Future<Result<List<String>>> _loadPlayerNames() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/names/names.json";
    final file = File(path);
    if (!await file.exists()) return Result.value([]);

    final jsonString = await file.readAsString();
    final list = json.decode(jsonString) as List<dynamic>;
    return Result.value(list.map((k) => k.toString()).toList());
  }

  static String newSaveGameName() {
    final DateFormat formatter = DateFormat("MMM d, HH-mm");
    return formatter.format(DateTime.now());
  }

  static String duplicatedSaveGameName(GameFrameStart root) {
    final DateFormat formatter = DateFormat("HH-mm-ss");
    final String suffix = formatter.format(DateTime.now());

    var gameName = root.gameName;
    var newGameName = "$gameName dup $suffix";
    return newGameName;
  }

  Future _saveTree(GameFrame frame) async {
    final root = frame.findFirst() as GameFrameStart;
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/games/${root.gameName}.json";
    final file = File(path);

    GameFrame? currentFrame = root;
    var structure = <String, dynamic>{};
    do {
      structure[currentFrame!.id] = currentFrame.toJson();
      currentFrame = currentFrame.next;
    } while (currentFrame != null);

    await file.create(recursive: true);
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
          var frame = GameFrameStart.fromJson(state);
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

        case "GameFrameNightRoleAction":
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

        case "GameFrameNarratorStateOverride":
          result = GameFrameNarratorStateOverride.fromJson(state);
          break;

        default:
          assert(false, "unknown type: ${kv.value["type"]}");
          break;
      }

      if (result != null) {
        result.id = kv.value["id"];
        result.dirty = kv.value["dirty"] as bool;
        result.time = DateTime.fromMillisecondsSinceEpoch(kv.value["time"]);
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
