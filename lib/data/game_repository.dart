import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_state.dart';

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
  final String fileName;
  final DateTime modifiedDate;
  final num frameCount;

  GameSaveFile(
    this.name,
    this.modifiedDate,
    this.fileName,
    this.path,
    this.frameCount,
  );
}

class GameScore {
  num get total =>
      winPoints +
      aliveBonusPoints +
      sheriffChecksPoints +
      doctorSavePoints +
      priestBlockedPoints +
      donFoundSheriffPoints +
      killerBonusPoints +
      mafiaGuessPoints +
      firstNightKilledPoints;

  final GamePlayer player;

  num winPoints = 0;
  num aliveBonusPoints = 0;
  num sheriffChecksPoints = 0;
  num doctorSavePoints = 0;
  num priestBlockedPoints = 0;
  num donFoundSheriffPoints = 0;
  num killerBonusPoints = 0;
  num mafiaGuessPoints = 0;
  num firstNightKilledPoints = 0;

  GameScore(this.player);
}

class GameRepository {
  final FileSystemService _fileSystemService;
  final GameConfigService _configService;

  final List<String> _playerNames = [];

  GameRepository(this._fileSystemService, this._configService) {
    _loadPlayerNames().then(
      (value) =>
          value.isValue ? _playerNames.addAll(value.asValue!.value) : null,
    );
  }

  Iterable<String> suggestPlayerNames(String input) {
    var result = <String>[];
    if (input.length < 3) return result;

    for (final name in _playerNames) {
      if (name.toLowerCase().contains(input.trim().toLowerCase())) {
        result.add(name.trim());
      }
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
    await saveTree(frame);
    root.fileName = fileName;
    root.gameName = gameName;
    return Result.value(newGameFileName);
  }

  Future delete(String fileName) async {
    await _fileSystemService.moveToBackupFolder(fileName);
  }

  Future undoDuplication(String fileName) async {
    await delete(fileName);
  }

  Future undoDeletion(String fileName) async {
    await _fileSystemService.moveFromBackupFolder(fileName);
  }

  Future undoLastDeletion() async {
    final backupGames = await iterateBackupGames();
    if (!backupGames.isValue) return;

    final lastBackup = backupGames.asValue?.value.firstOrNull;
    if (lastBackup == null) return;
    await undoDeletion(lastBackup.fileName);
  }

  Future<Result<GameState>> loadGame(GameSaveFile file) async {
    try {
      final frame = await _loadTree(file);

      if (frame.isError) {
        return frame.asError!;
      } else {
        return Result.value(GameState.calculate(frame.asValue!.value));
      }
    } catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<Iterable<GameSaveFile>>> iterateSavedGames() async {
    return _iterateSavedGamesFolder("games");
  }

  Future<Result<Iterable<GameSaveFile>>> iterateBackupGames() async {
    return _iterateSavedGamesFolder("gamesBackup");
  }

  Future<Result<Iterable<GameSaveFile>>> _iterateSavedGamesFolder(
    String folder,
  ) async {
    var result = List<GameSaveFile>.empty(growable: true);
    final dir = await _fileSystemService.openSaveGameDirectory(folder);
    if (!await dir.exists()) return Result.value(result);

    await for (final entity in dir.list()) {
      if (entity is File && entity.uri.pathSegments.last.endsWith(".json")) {
        try {
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
            GameSaveFile(
              name,
              await entity.lastModified(),
              entity.uri.pathSegments.last,
              entity.path,
              dict.length,
            ),
          );
        } catch (error) {
          result.add(
            GameSaveFile(
              "${entity.uri.pathSegments.last} (invalid)",
              await entity.lastModified(),
              entity.uri.pathSegments.last,
              entity.path,
              0,
            ),
          );
        }
      }
    }

    result.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return Result.value(result);
  }

  List<GameScore> calculateScores(GameFrame frame) {
    var result = <GameScore>[];
    var state = GameState.calculate(frame, ignoreLast: false);

    for (final player in state.players) {
      var score = GameScore(player);
      switch (state.gameResult) {
        case GameResult.killerWon:
          if (player.role == GameRole.killer) {
            score.winPoints = _configService.killerWinPoints;
          }
          break;
        case GameResult.mafiaWon:
          if (player.role.isMafia) {
            score.winPoints = _configService.mafiaWinPoints;

            if (player.alive) {
              score.aliveBonusPoints = _configService.mafiaAliveWinBonusPoints;
            }
          }
          break;
        case GameResult.civiliansWon:
          if (player.role.isCivilian) {
            score.winPoints = _configService.civilianWinPoints;
          }
          break;
        case GameResult.killerMafiaDraw:
          if (player.role.isMafia) {
            score.winPoints = _configService.kmDrawMafiaPoints;
          }
          if (player.role.isKiller) {
            score.winPoints = _configService.kmDrawKillerPoints;
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
            if (state.players[guessIndex].role.isMafia) {
              guessedCorrectly++;
            }
          }

          final blackTeamCount =
              3 + (state.rolesInTheGame.contains(GameRole.priest) ? 1 : 0);

          if (guessedCorrectly >= blackTeamCount) {
            score.mafiaGuessPoints = _configService.guessPointsFull;
          } else if (guessedCorrectly >= blackTeamCount / 2) {
            score.mafiaGuessPoints = _configService.guessPointsHalf;
          }

          score.firstNightKilledPoints = _configService.firstNightKillPoints;
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
            _configService.sheriffFoundOpposingPlayersPoints *
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
                score.doctorSavePoints +=
                    _configService.doctorSavedCivilianPoints;
                break;
              case GameRole.sheriff:
                score.doctorSavePoints +=
                    _configService.doctorSavedSheriffPoints;
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
              score.killerBonusPoints +=
                  _configService.killerActiveRoleKillPoints;
              break;
            case GameRole.doctor:
              score.killerBonusPoints +=
                  _configService.killerActiveRoleKillPoints;
              break;
            case GameRole.mafia:
              score.killerBonusPoints +=
                  _configService.killerActiveRoleKillPoints;
              break;
            case GameRole.don:
              score.killerBonusPoints +=
                  _configService.killerActiveRoleKillPoints;
              break;
            case GameRole.priest:
              score.killerBonusPoints +=
                  _configService.killerActiveRoleKillPoints;
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
              score.priestBlockedPoints +=
                  _configService.priestBlockedSheriffPoints;
              break;
            case GameRole.doctor:
              score.priestBlockedPoints +=
                  _configService.priestBlockedDoctorPoints;
              break;
            case GameRole.killer:
              score.priestBlockedPoints +=
                  _configService.priestBlockedKilledPoints;
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
          score.donFoundSheriffPoints = _configService.donFoundSheriffPoints;
        }
      }

      result.add(score);
    }

    return result;
  }

  List<List<String>> exportNightActionsToSheets(GameFrame frame) {
    String seatName(int? index) =>
        index != null ? GamePlayer.seatNameFromIndex(index) : '';

    // 6 rows, one per role: priest, mafia, don, sheriff, doctor, killer
    final List<String> priestRow = [];
    final List<String> mafiaRow = [];
    final List<String> donRow = [];
    final List<String> sheriffRow = [];
    final List<String> doctorRow = [];
    final List<String> killerRow = [];

    bool inNight = false;
    bool hasNight = false;
    int? priestIndex,
        mafiaIndex,
        donIndex,
        sheriffIndex,
        doctorIndex,
        killerIndex;

    GameFrame? current = frame.findFirst();
    while (current != null) {
      switch (current) {
        case GameFrameNightStart _:
          inNight = true;
          priestIndex = null;
          mafiaIndex = null;
          donIndex = null;
          sheriffIndex = null;
          doctorIndex = null;
          killerIndex = null;
        case GameFrameNightRoleAction f:
          if (inNight) {
            switch (f.role) {
              case GameRole.priest:
                priestIndex = f.index;
              case GameRole.mafia:
                mafiaIndex = f.index;
              case GameRole.don:
                donIndex = f.index;
              case GameRole.sheriff:
                sheriffIndex = f.index;
              case GameRole.doctor:
                doctorIndex = f.index;
              case GameRole.killer:
                killerIndex = f.index;
              default:
                break;
            }
          }
        case GameFrameDayStart _:
          if (inNight) {
            if (hasNight) {
              priestRow.addAll(['', '', '', '']);
              mafiaRow.addAll(['', '', '', '']);
              donRow.addAll(['', '', '', '']);
              sheriffRow.addAll(['', '', '', '']);
              doctorRow.addAll(['', '', '', '']);
              killerRow.addAll(['', '', '', '']);
            }
            priestRow.add(seatName(priestIndex));
            mafiaRow.add(seatName(mafiaIndex));
            donRow.add(seatName(donIndex));
            sheriffRow.add(seatName(sheriffIndex));
            doctorRow.add(seatName(doctorIndex));
            killerRow.add(seatName(killerIndex));
            hasNight = true;
            inNight = false;
          }
        default:
          break;
      }
      if (current == frame) break;
      current = current.next;
    }

    if (!hasNight) return [];
    return [priestRow, mafiaRow, donRow, sheriffRow, doctorRow, killerRow];
  }

  List<List<String>> exportFirstNightGuessesToSheet(GameFrame frame) {
    final farewellFrame = frame.findBackwards<GameFrameDayFarewellSpeech>(
      (f) => f.firstNight,
    );
    if (farewellFrame == null) return [];

    final guesses = farewellFrame.firstNightGuesses;
    final maxGuesses = guesses.fold(
      0,
      (max, g) => g.length > max ? g.length : max,
    );

    final List<List<String>> rows = [];
    for (int row = 0; row < maxGuesses; row++) {
      final List<String> rowData = [];
      for (int col = 0; col < guesses.length; col++) {
        final list = guesses[col];
        rowData.add(
          row < list.length ? GamePlayer.seatNameFromIndex(list[row]) : '',
        );
      }
      rows.add(rowData);
    }
    return rows;
  }

  List<List<String>> exportDayActionsToSheet(GameFrame frame) {
    final state = GameState.calculate(frame, ignoreLast: false);
    final players = state.players;

    final List<Map<int, int?>> dailyNominees = [];
    final List<Map<int, int>> dailyVotes = [];
    final List<Map<int, int>> dailyAllLeavingVotes = [];
    final List<bool?> dailyAllLeavingResults = [];

    Map<int, int?> currentNominees = {};
    Map<int, int> currentVotes = {};
    Map<int, int> currentAllLeavingVotes = {};
    bool inDay = false;
    bool? currentAllLeavingResult;
    Set<int> currentAllLeavingPlayers = {};

    GameFrame? current = frame.findFirst();
    while (current != null) {
      switch (current) {
        case GameFrameDayStart _:
          inDay = true;
          currentNominees = {};
          currentVotes = {};
          currentAllLeavingVotes = {};
          currentAllLeavingResult = null;
          currentAllLeavingPlayers = {};
        case GameFrameDaySpeech f:
          if (inDay) currentNominees[f.index] = f.putUpForVoteIndex;
        case GameFrameDayVoteOnPlayerLeaving f:
          if (inDay) currentVotes[f.playerToVoteFor] = f.voteCount;
        case GameFrameDayVoteOnAllLeaving f:
          if (inDay) {
            for (final playerIndex in f.playersToVoteFor) {
              currentAllLeavingVotes[playerIndex] = f.voteCount;
            }
            currentAllLeavingResult = false;
            currentAllLeavingPlayers = f.playersToVoteFor.toSet();
          }
        case GameFrameDayPlayersVotedOut f:
          if (inDay && currentAllLeavingResult != null) {
            final votedOut = f.playersVotedOut.toSet();
            if (votedOut.containsAll(currentAllLeavingPlayers) &&
                currentAllLeavingPlayers.containsAll(votedOut)) {
              currentAllLeavingResult = true;
            }
          }
        case GameFrameNightStart _:
          if (inDay) {
            dailyNominees.add(currentNominees);
            dailyVotes.add(currentVotes);
            dailyAllLeavingVotes.add(currentAllLeavingVotes);
            dailyAllLeavingResults.add(currentAllLeavingResult);
            inDay = false;
          }
        default:
          break;
      }
      if (current == frame) break;
      current = current.next;
    }

    final List<List<String>> rows = [];
    for (final player in players) {
      final List<String> row = [
        player.name,
        switch (player.role) {
          GameRole.civilian => 'Мирний',
          GameRole.mafia => 'Мафія',
          GameRole.don => 'Дон',
          GameRole.sheriff => 'Шериф',
          GameRole.doctor => 'Лікар',
          GameRole.priest => 'Священик',
          GameRole.killer => 'Кіллер',
          GameRole.none => '',
        },
        player.penalties.toString(),
      ];
      for (int day = 0; day < dailyNominees.length; day++) {
        final nomineeIndex = dailyNominees[day][player.index];
        final nomineeName = nomineeIndex != null
            ? players[nomineeIndex].seatName
            : '';
        final votes = nomineeIndex != null
            ? (dailyVotes[day][nomineeIndex]?.toString() ?? '-')
            : '';
        final allLeavingVotes = nomineeIndex != null
            ? (dailyAllLeavingVotes[day][nomineeIndex]?.toString() ?? '-')
            : '';
        final allLeavingResult = player.index == 8
            ? switch (dailyAllLeavingResults[day]) {
                true => 'Leave',
                false => 'Stay',
                null => '',
              }
            : '';
        row.addAll([nomineeName, votes, allLeavingVotes, allLeavingResult, '']);
      }
      rows.add(row);
    }

    return rows;
  }

  void _savePlayerNames(Iterable<String> names) async {
    final file = await _fileSystemService.openPlayerNamesFile();
    await file.writeAsString(json.encode(names));
  }

  Future<Result<List<String>>> _loadPlayerNames() async {
    final file = await _fileSystemService.openPlayerNamesFile();
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

  Future saveTree(GameFrame frame) async {
    final root = frame.findFirst() as GameFrameStart;
    final file = await _fileSystemService.openSaveGameFile(
      "${root.fileName}.json",
    );

    GameFrame? currentFrame = root;
    var structure = <String, dynamic>{};
    do {
      structure[currentFrame!.id] = currentFrame.toJson();
      currentFrame = currentFrame.next;
    } while (currentFrame != null);

    await file.create(recursive: true);
    await file.writeAsString(json.encode(structure));
  }

  Future<Result<GameFrame>> _loadTree(GameSaveFile saveFile) async {
    final file = await _fileSystemService.openSaveGameFile(saveFile.fileName);
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

        case "GameFrameZeroNightStart":
          result = GameFrameZeroNightStart.fromJson(state);
          break;

        case "GameFrameDayStart":
          result = GameFrameDayStart.fromJson(state);
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
