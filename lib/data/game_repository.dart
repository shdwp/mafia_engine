import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
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

class GameScore {
  num get total =>
      winPoints +
      aliveBonusPoints +
      sheriffChecksPoints +
      doctorSavePoints +
      priestBlockedPoints +
      donFoundSheriffPoints +
      killerBonusPoints;

  final GamePlayer player;

  num winPoints = 0;
  num aliveBonusPoints = 0;
  num sheriffChecksPoints = 0;
  num doctorSavePoints = 0;
  num priestBlockedPoints = 0;
  num donFoundSheriffPoints = 0;
  num killerBonusPoints = 0;
  num mafiaGuessPoints = 0;

  GameScore(this.player);
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
    return GameState.calculate(GameFrameStart());
  }

  Future<Result<String>> duplicate(GameFrame frame) async {
    var root = frame.findFirst() as GameFrameStart;
    var fileName = root.fileName;
    var gameName = root.gameName;

    var newGameFileName = "$fileName ${duplicationSuffix()}";

    root.fileName = newGameFileName;
    root.gameName = "$gameName ${duplicationSuffix()}";
    await _saveTree(frame);
    root.fileName = fileName;
    root.gameName = gameName;
    return Result.value(newGameFileName);
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
      return Result.value(GameState.calculate(frame.asValue!.value));
    }
  }

  Future<Result<Iterable<GameSaveFile>>> iterateSavedGames() async {
    var result = List<GameSaveFile>.empty(growable: true);
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory("${directory.path}/games/");
    if (!dir.existsSync()) return Result.value(result);

    await for (final entity in dir.list()) {
      if (entity is File && entity.uri.pathSegments.last.endsWith(".json")) {
        final jsonString = await entity.readAsString();
        final dict = json.decode(jsonString) as Map<String, dynamic>;

        var name = entity.uri.pathSegments.last;
        for (final kv in dict.entries) {
          final state = GameLoadState(kv.value as Map<String, dynamic>);
          if (kv.value["type"] == "GameFrameStart") {
            final frame = GameFrameStart.fromJson(state);
            name = frame.gameName;
            break;
          }
        }

        result.add(
          GameSaveFile(name, await entity.lastModified(), entity.path),
        );
      }
    }

    result.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return Result.value(result);
  }

  Result<GameState> moveBackward(GameFrame currentFrame) {
    return currentFrame.previous != null
        ? Result.value(GameState.calculate(currentFrame.previous!))
        : Result.error(GameError.noPrevious);
  }

  Result<GameState> moveForward(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    if (currentFrame.next != null) {
      return Result.value(GameState.calculate(currentFrame.next!));
    }

    return Result.error(GameError.noNext);
  }

  Result<GameState> moveTop(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    final lastFrame = currentFrame.findLast();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> moveBottom(GameFrame currentFrame) {
    final lastFrame = currentFrame.findFirst();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> setTop(GameFrame currentFrame) {
    currentFrame.next = null;
    final lastFrame = currentFrame.findLast();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> commitFrame(GameFrame frame) {
    if (!frame.isDirty) return Result.error(GameError.frameNotDirty);
    if (!frame.isValid) return Result.error(GameError.frameInvalid);

    if (frame is GameFrameAddPlayers) {
      commitPlayerNames(frame.players);
    }

    var state = GameState.calculate(frame, ignoreLast: false);
    frame.previous?.next = frame;
    frame.dirty = false;
    frame.next = GameState.createNextFrame(frame, state);
    frame.next!.previous = frame;

    _saveTree(frame);
    return Result.value(GameState.calculate(frame.next!));
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

    var state = GameState.calculate(newFrame);
    _saveTree(newFrame);
    return Result.value(state);
  }

  Result<GameState> override(GameFrame frame) {
    var state = GameState.calculate(frame);
    var newFrame = GameFrameNarratorStateOverride(
      GameFrameNarratorStateOverrideType.dayStart,
      state.players.map((p) {
        return (p.name, p.role, p.alive, p.penalties);
      }).toList(),
    );
    frame.previous!.next = newFrame;
    newFrame.previous = frame.previous!;
    frame.previous = newFrame;

    var newState = GameState.calculate(newFrame);
    _saveTree(newFrame);
    return Result.value(newState);
  }

  List<GameScore> calculateScores(GameFrame frame) {
    var result = <GameScore>[];
    var state = GameState.calculate(frame, ignoreLast: false);
    var config = GameConfigService();

    for (final player in state.players) {
      var score = GameScore(player);
      switch (state.gameResult) {
        case GameResult.killerWon:
          if (player.role == GameRole.killer) {
            score.winPoints = config.killerWinPoints;
          }
          break;
        case GameResult.mafiaWon:
          if (player.role.isMafia) {
            score.winPoints = config.mafiaWinPoints;

            if (player.alive) {
              score.aliveBonusPoints = config.mafiaAliveWinBonusPoints;
            }
          }
          break;
        case GameResult.civiliansWon:
          if (player.role.isCivilian) {
            score.winPoints = config.civilianWinPoints;
          }
          break;
        case GameResult.killerMafiaDraw:
          if (player.role.isMafia) {
            score.winPoints = config.kmDrawMafiaPoints;
          }
          if (player.role.isKiller) {
            score.winPoints = config.kmDrawKillerPoints;
          }
          break;
        default:
          break;
      }

      if (player.role.isCivilian || player.role.isKiller) {
        var firstNightFarewell = frame
            .findBackwards<GameFrameDayFarewellSpeech>((f) => f.firstNight);

        final guessIndex = firstNightFarewell?.playersKilled.indexOf(
          player.index,
        );

        if (guessIndex != null && guessIndex != -1) {
          num guessedCorrectly = 0;
          for (final guessIndex
              in firstNightFarewell!.firstNightGuesses[guessIndex]) {
            if (state.players[guessIndex].role.isMafia) {}
            guessedCorrectly++;
          }

          final blackTeamCount =
              3 + (state.rolesInTheGame.contains(GameRole.priest) ? 1 : 0);

          if (guessedCorrectly >= blackTeamCount) {
            score.mafiaGuessPoints = config.guessPointsFull;
          } else if (guessedCorrectly >= blackTeamCount / 2) {
            score.mafiaGuessPoints = config.guessPointsHalf;
          }
        }
      }

      if (player.role == GameRole.sheriff) {
        var frames = frame.findAllPredicate<GameFrameNightRoleAction>(
          (f) => f.role == GameRole.sheriff,
        );

        var blackCheckedPlayers = <int>{};
        for (final frame in frames) {
          if (frame.index == null) continue;

          if (state.players[frame.index!].role.isMafia) {
            blackCheckedPlayers.add(frame.index!);
          }

          if (state.players[frame.index!].role.isKiller) {
            var stateAtTheTime = GameState.calculate(frame, ignoreLast: false);
            if (stateAtTheTime.mafiaCount == 0) {
              blackCheckedPlayers.add(frame.index!);
            }
          }
        }

        score.sheriffChecksPoints +=
            config.sheriffFoundOpposingPlayersPoints *
            blackCheckedPlayers.length;
      }

      if (player.role == GameRole.doctor) {
        var frames = frame.findAllPredicate<GameFrameNightRoleAction>(
          (f) => f.role == GameRole.doctor,
        );
        for (final frame in frames) {
          if (frame.index == null) continue;

          final firstNightFrame = frame.findBackwards(
            (f) => f is GameFrameNightStart,
          );

          final mafiaAction = firstNightFrame
              ?.findForwards<GameFrameNightRoleAction>(
                (f) => f.role == GameRole.mafia,
              );

          final killerAction = firstNightFrame
              ?.findForwards<GameFrameNightRoleAction>(
                (f) => f.role == GameRole.killer,
              );

          if (mafiaAction?.index == frame.index ||
              killerAction?.index == frame.index) {
            switch (state.players[frame.index!].role) {
              case GameRole.doctor:
              case GameRole.civilian:
                score.doctorSavePoints += config.doctorSavedCivilianPoints;
                break;
              case GameRole.sheriff:
                score.doctorSavePoints += config.doctorSavedSheriffPoints;
                break;
              default:
                break;
            }
          }
        }
      }

      if (player.role == GameRole.killer) {
        var frames = frame.findAllPredicate<GameFrameNightRoleAction>(
          (f) => f.role == GameRole.killer,
        );
        for (final frame in frames) {
          if (frame.index == null) continue;

          switch (state.players[frame.index!].role) {
            case GameRole.sheriff:
              score.killerBonusPoints += config.killerActiveRoleKillPoints;
              break;
            case GameRole.doctor:
              score.killerBonusPoints += config.killerActiveRoleKillPoints;
              break;
            case GameRole.mafia:
              score.killerBonusPoints += config.killerActiveRoleKillPoints;
              break;
            case GameRole.don:
              score.killerBonusPoints += config.killerActiveRoleKillPoints;
              break;
            case GameRole.priest:
              score.killerBonusPoints += config.killerActiveRoleKillPoints;
              break;
            default:
              break;
          }
        }
      }

      if (player.role == GameRole.priest) {
        var frames = frame.findAllPredicate<GameFrameNightRoleAction>(
          (f) => f.role == GameRole.priest,
        );
        for (final frame in frames) {
          if (frame.index == null) continue;

          switch (state.players[frame.index!].role) {
            case GameRole.sheriff:
              score.priestBlockedPoints += config.priestBlockedSheriffPoints;
              break;
            case GameRole.doctor:
              score.priestBlockedPoints += config.priestBlockedDoctorPoints;
              break;
            case GameRole.killer:
              score.priestBlockedPoints += config.priestBlockedKilledPoints;
              break;
            default:
              break;
          }
        }
      }

      if (player.role == GameRole.don) {
        var foundSheriff = false;
        var frames = frame.findAllPredicate<GameFrameNightRoleAction>(
          (f) => f.role == GameRole.don,
        );

        for (final frame in frames) {
          if (frame.index == null) continue;

          if (state.players[frame.index!].role == GameRole.sheriff) {
            foundSheriff = true;
          }
        }

        if (foundSheriff) {
          score.donFoundSheriffPoints = config.donFoundSheriffPoints;
        }
      }

      result.add(score);
    }

    return result;
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

  static String newGameName() {
    final DateFormat formatter = DateFormat("MMM d, HH:mm");
    return formatter.format(DateTime.now());
  }

  static String newSaveGameFileName() {
    final DateFormat formatter = DateFormat("MMM d, HH-mm");
    return formatter.format(DateTime.now());
  }

  static String duplicatedSaveGameFileName(GameFrameStart root) {
    final DateFormat formatter = DateFormat("HH-mm-ss");
    final String suffix = formatter.format(DateTime.now());

    var gameName = root.gameName;
    var newGameName = "$gameName dup $suffix";
    return newGameName;
  }

  static String duplicationSuffix() {
    final DateFormat formatter = DateFormat("HH-mm-ss");
    final String suffix = formatter.format(DateTime.now());

    return "dup $suffix";
  }

  Future _saveTree(GameFrame frame) async {
    final root = frame.findFirst() as GameFrameStart;
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/games/${root.fileName}.json";
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
