import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';

import 'game_frame_tree.dart';

enum GameStateDayNextStage { playerSpeech, night, voting, invalid }

class GameCriticalDayCalculation {
  final int votingAttempts;
  final List<String> log;

  GameCriticalDayCalculation(this.votingAttempts, this.log);
}

class GameState {
  const GameState(
    this.rootFrame,
    this.frameCount,
    this.frameIndex,
    this.lastFrame,
    this.gameResult,
    this.players,
    this.dayCount,
    this.isNightPhase,
    this.voteMap,
    this.lastPriestBlock,
    this.currentNightBlockedPlayer,
    this.lastDoctorHeal,
    this.playersUpForVote,
    this.rolesInTheGame,
  );

  final GameFrame rootFrame;
  final int frameCount;
  final int frameIndex;
  final GameFrame lastFrame;
  final GameResult gameResult;
  final List<GamePlayer> players;
  final int dayCount;

  final bool isNightPhase;
  final int? lastPriestBlock;
  final int? lastDoctorHeal;
  final Map<int, List<int>> voteMap;
  final GamePlayer? currentNightBlockedPlayer;
  final List<GamePlayer> playersUpForVote;
  final List<GameRole> rolesInTheGame;

  int get aliveCount => players.where((p) => p.alive).length;
  int get aliveCivilianCount => players.civilians.where((p) => p.alive).length;
  int get mafiaCount => players.mafiosi.where((p) => p.alive).length;
  int get killerCount => players.killers.where((p) => p.alive).length;

  static GameState calculate(GameFrame lastFrame, {bool ignoreLast = true}) {
    var players = List<GamePlayer>.empty(growable: true);
    var playersUpForVote = <GamePlayer>[];
    var rolesInTheGame = <GameRole>[];
    Map<int, List<int>> voteMap = {};
    int? priestTarget;
    int? lastPriestTarget;
    int? lastDoctorTarget;
    bool isNightPhase = true;
    int dayCount = 0;

    var rootFrame = lastFrame.findFirst();
    GameFrame? frame = rootFrame;
    while (frame != null) {
      if (!ignoreLast || frame != lastFrame) {
        switch (frame) {
          case GameFrameAddPlayers addPlayersFrame:
            isNightPhase = true;
            players.addAll(
              addPlayersFrame.players.indexed.map(
                (kv) => GamePlayer(kv.$1, kv.$2),
              ),
            );
            rolesInTheGame = addPlayersFrame.roles;
            break;

          case GameFrameAssignRole assignRoleFrame:
            players[assignRoleFrame.index].role = assignRoleFrame.role;
            break;

          case GameFrameDaySpeech frame:
            if (frame.putUpForVoteIndex != null) {
              playersUpForVote.add(players[frame.putUpForVoteIndex!]);
            }
            break;

          case GameFrameDayVotingStart _:
            voteMap.clear();
            break;

          case GameFrameDayVoteOnPlayerLeaving voteFrame:
            voteMap[voteFrame.playerToVoteFor] = voteFrame.votes;
            break;

          case GameFrameDayVoteOnAllLeaving voteFrame:
            voteMap[-1] = voteFrame.votes;
            break;

          case GameFrameNightStart _:
            isNightPhase = true;
            priestTarget = null;
            playersUpForVote.clear();
            break;

          case GameFrameNightRoleAction frame:
            if (frame.role == GameRole.priest) {
              priestTarget = frame.index;
              lastPriestTarget = frame.index;
            }

            if (frame.role == GameRole.doctor) {
              lastDoctorTarget = frame.index;
            }
            break;
        }
      }

      switch (frame) {
        case GameFrameNightStart _:
          isNightPhase = true;
          break;

        case GameFrameDayStart _:
          isNightPhase = false;
          dayCount++;
          break;

        case GameFrameDaySpeech _:
          isNightPhase = false;
          break;

        case GameFrameDayFarewellSpeech frame:
          isNightPhase = false;
          for (final index in frame.playersKilled) {
            final player = players[index];
            player.alive = false;
          }
          break;

        case GameFrameNarratorPenalize penaltyFrame:
          if (penaltyFrame.index != null) {
            final player = players[penaltyFrame.index!];
            player.penalties += penaltyFrame.amount;

            if (player.penalties >= 4) player.alive = false;
          }
          break;

        case GameFrameDayPlayersVotedOut votedOutFrame:
          for (final index in votedOutFrame.playersVotedOut) {
            final player = players[index];
            player.alive = false;
          }
          break;

        case GameFrameNarratorStateOverride frame:
          isNightPhase =
              frame.type == GameFrameNarratorStateOverrideType.nightStart;
          players.clear();
          rolesInTheGame.clear();
          playersUpForVote.clear();
          voteMap.clear();
          for (final kv in frame.players.indexed) {
            var model = GamePlayer(kv.$1, kv.$2.$1);
            model.role = kv.$2.$2;
            model.penalties = kv.$2.$4;
            model.alive = kv.$2.$3;
            players.add(model);

            if (!rolesInTheGame.contains(model.role)) {
              rolesInTheGame.add(model.role);
            }
          }
          break;
      }

      if (frame == lastFrame) break;
      frame = frame.next;
    }

    var gameEndResult = GameState.checkForGameEnd(lastFrame, players);
    return GameState(
      rootFrame,
      rootFrame.countNext(),
      lastFrame.countPrevious(),
      lastFrame,
      gameEndResult,
      players,
      dayCount,
      isNightPhase,
      voteMap,
      lastPriestTarget,
      priestTarget != null ? players[priestTarget] : null,
      lastDoctorTarget,
      playersUpForVote,
      rolesInTheGame,
    );
  }

  static GameFrame? createNextFrame(
    GameFrame last,
    GameState state, {
    bool defensiveSpeechesAlwaysAvailable = true,
  }) {
    GameFrame? next;
    var players = state.players;
    switch (last) {
      case GameFrameStart _:
        next = GameFrameAddPlayers();
        break;

      case GameFrameAddPlayers _:
        next = GameFrameZeroNightStart();
        break;

      case GameFrameZeroNightStart _:
      case GameFrameAssignRole _:
        var unassigned = players.where((p) => p.role == GameRole.none);
        if (unassigned.isNotEmpty) {
          next = GameFrameAssignRole(unassigned.first.index);
        } else {
          next = _nextZeroNightMeetFrame(last, players);
          assert(next != null);
        }
        break;

      case GameFrameZeroNightMeet _:
        next = _nextZeroNightMeetFrame(last, players) ?? GameFrameDayStart();
        break;

      case GameFrameDaySpeech frame:
        var allSpeechFrames = frame
            .takeAllBackwardsIncludingUntil<GameFrameDaySpeech>(
              (f) => f.dayOpening,
            );

        var allPlayersSpoke = true;
        final allPlayers = players.whereAlive();
        for (final player in allPlayers) {
          if (!allSpeechFrames.any((f) => f.index == player.index)) {
            allPlayersSpoke = false;
            break;
          }
        }

        if (allPlayersSpoke) {
          next = _votingStartFrame(frame, players) ?? GameFrameNightStart();
        } else {
          var nextPlayer = players.findNextAlive(frame.index);
          next = GameFrameDaySpeech(nextPlayer.index, false);
        }
        break;

      case GameFrameDayVotingStart frame:
        final isRepeatedVote = frame.previousVoteIndexes.isNotEmpty;
        if (defensiveSpeechesAlwaysAvailable || isRepeatedVote) {
          next = _nextVotingSpeechFrame(frame, players)!;
        } else {
          next = _nextVotingFrame(frame, players) ?? GameFrameNightStart();
        }
        break;

      case GameFrameDayPlayerVotingSpeech frame:
        next =
            _nextVotingSpeechFrame(frame, players) ??
            _nextVotingFrame(frame, players) ??
            GameFrameNightStart();
        break;

      case GameFrameDayVoteOnPlayerLeaving frame:
        next = _nextVotingFrame(frame, players) ?? GameFrameNightStart();
        break;

      case GameFrameDayVoteOnAllLeaving frame:
        next = _allLeavingResultFrame(frame, players) ?? GameFrameNightStart();
        break;

      case GameFrameDayPlayersVotedOut _:
        next = GameFrameNightStart();
        break;

      case GameFrameNightStart frame:
        next = _nextNightFrame(frame, players) ?? GameFrameDayStart();
        break;

      case GameFrameDayStart frame:
        next =
            _nextFarewellFrame(frame, players) ??
            _firstDayFrame(frame, players);
        break;

      case GameFrameNightRoleAction frame:
        next = _nextNightFrame(frame, players) ?? GameFrameDayStart();
        break;

      case GameFrameDayFarewellSpeech frame:
        next =
            _nextFarewellFrame(frame, players) ??
            _firstDayFrame(frame, players);
        break;

      case GameFrameNarratorStateOverride frame:
        next = frame.type == GameFrameNarratorStateOverrideType.dayStart
            ? _firstDayFrame(frame, players)
            : GameFrameNightStart();
        break;
    }

    if (next == null) return null;
    next.previous = last;
    return next;
  }

  static (GameStateDayNextStage, GamePlayer?) calculateNextDaySegment(
    GameFrame frame,
    GameState state, {
    bool defensiveSpeechesAlwaysAvailable = true,
  }) {
    if (state.isNightPhase) return (GameStateDayNextStage.invalid, null);
    final next = createNextFrame(
      frame,
      state,
      defensiveSpeechesAlwaysAvailable: defensiveSpeechesAlwaysAvailable,
    );
    return switch (next) {
      GameFrameDaySpeech f => (
        GameStateDayNextStage.playerSpeech,
        state.players[f.index],
      ),
      GameFrameDayVotingStart _ => (GameStateDayNextStage.voting, null),
      GameFrameNightStart _ => (GameStateDayNextStage.night, null),
      _ => (GameStateDayNextStage.invalid, null),
    };
  }

  static GameCriticalDayCalculation calculateCriticalDay(
    int playerCount,
    List<GameRole> roles,
  ) {
    List<String> log = [];
    var amountOfVotes = 0;

    int mafiaCount = 3 + (roles.contains(GameRole.priest) ? 1 : 0);
    int nonMafiaCount = playerCount - mafiaCount;

    final mafiaPoints = 7 + 2 + (roles.contains(GameRole.priest) ? 3 : 0);
    final civPoints =
        4 +
        (roles.contains(GameRole.doctor) ? 4 : 0) +
        nonMafiaCount -
        1 -
        (roles.contains(GameRole.killer) ? 1 : 0) -
        (roles.contains(GameRole.doctor) ? 1 : 0);

    String constructStatus(count) {
      return "$count vs $mafiaCount";
    }

    final killerPoints = roles.contains(GameRole.killer) ? 6 : 0;
    final totalPoints = civPoints + mafiaPoints + killerPoints;

    var probabilityString =
        "📈 civ ${(civPoints / totalPoints * 100).toInt()}%, mafia ${(mafiaPoints / totalPoints * 100).toInt()}%";

    if (roles.contains(GameRole.killer)) {
      probabilityString +=
          ", killer ${(killerPoints / totalPoints * 100).toInt()}%";
    }
    log.add(probabilityString);

    if (roles.contains(GameRole.killer)) {
      var count = nonMafiaCount;

      log.add("☀️ Day 1 ☀️");
      amountOfVotes++;
      count--;
      log.add("Day 1 vote kill, ${constructStatus(count)}");

      for (var day = 2; day < 99; day++) {
        log.add("☀️ Day $day ☀️");
        count--;
        log.add("Night mafia kill, ${constructStatus(count)}");
        count--;
        log.add("Night killer kill, ${constructStatus(count)}");
        if (count < mafiaCount) {
          log.add("✅ Mafia won during night, day $day");
          break;
        }

        amountOfVotes++;
        count--;
        log.add("Day $day vote kill, ${constructStatus(count)}");

        if (count < mafiaCount) {
          log.add("✅ Mafia won during day $day");
          break;
        }
      }
    } else {
      var count = nonMafiaCount;

      log.add("☀️ Day 1 ☀️");
      amountOfVotes++;
      count--;
      log.add("Day 1 vote kill, ${constructStatus(count)}");

      for (var day = 2; day < 99; day++) {
        log.add("☀️ Day $day ☀️");

        count--;
        log.add("Night mafia kill, ${constructStatus(count)}");

        if (count <= mafiaCount) {
          log.add("✅ Mafia won during night, day $day");
          break;
        }

        amountOfVotes++;
        count--;
        log.add("Day $day vote kill, ${constructStatus(count)}");

        if (count <= mafiaCount) {
          log.add("✅ Mafia won during day $day");
          break;
        }
      }
    }

    return GameCriticalDayCalculation(amountOfVotes, log);
  }

  static GameFrame _firstDayFrame(GameFrame frame, List<GamePlayer> players) {
    final lastOverride = frame.firstBackwards<GameFrameNarratorStateOverride>();
    final lastFirstSpeechFrame = frame.findBackwards<GameFrameDaySpeech>(
      (f) => f.dayOpening,
    );

    if (lastOverride?.firstToTalk != null && lastFirstSpeechFrame != null) {
      if (lastOverride!.time.compareTo(lastFirstSpeechFrame.time) > 0) {
        return GameFrameDaySpeech(lastOverride.firstToTalk!, true);
      } else {
        var nextPlayer = players.findNextAlive(lastFirstSpeechFrame.index);
        return GameFrameDaySpeech(nextPlayer.index, true);
      }
    } else if (lastOverride?.firstToTalk != null) {
      return GameFrameDaySpeech(lastOverride!.firstToTalk!, true);
    } else if (lastFirstSpeechFrame != null) {
      var nextPlayer = players.findNextAlive(lastFirstSpeechFrame.index);
      return GameFrameDaySpeech(nextPlayer.index, true);
    } else {
      return GameFrameDaySpeech(players.first.index, true);
    }
  }

  static GameFrame? _nextFarewellFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    final allNights = frame.takeBackUntil<GameFrameNightStart>(
      frame.findFirst(),
    );
    final nightStart = frame.firstBackwards<GameFrameNightStart>();
    if (nightStart == null) return null;

    int? mafiaTarget;
    int? priestTarget;
    int? doctorTarget;
    int? killerTarget;

    for (final actionFrame in frame.takeBackUntil<GameFrameNightRoleAction>(
      nightStart!,
    )) {
      switch (actionFrame.role) {
        case GameRole.mafia:
          mafiaTarget = actionFrame.index;
          break;
        case GameRole.priest:
          priestTarget = actionFrame.index;
          break;
        case GameRole.doctor:
          doctorTarget = actionFrame.index;
          break;
        case GameRole.killer:
          killerTarget = actionFrame.index;
          break;
        default:
          break;
      }
    }

    List<int> killedIndices = [];
    if (mafiaTarget != null && mafiaTarget != doctorTarget) {
      killedIndices.add(mafiaTarget);
    }

    if (killerTarget != null && killerTarget != doctorTarget) {
      killedIndices.add(killerTarget);
    }

    killedIndices.shuffle();
    final farewellFrames = frame.takeBackUntil<GameFrameDayFarewellSpeech>(
      nightStart,
    );

    if (farewellFrames.isEmpty && killedIndices.isNotEmpty) {
      return GameFrameDayFarewellSpeech(killedIndices, allNights.length == 1);
    }

    return null;
  }

  static GameFrame? _nextZeroNightMeetFrame(
    GameFrame last,
    List<GamePlayer> players,
  ) {
    bool hasKiller = players.any((p) => p.role == GameRole.killer);
    bool hasDoctor = players.any((p) => p.role == GameRole.doctor);

    var mafiaMet = last.findAllPreceeding((frame) {
      if (frame is GameFrameZeroNightMeet) {
        return frame.roleGroup.isMafia;
      } else {
        return false;
      }
    }).isNotEmpty;
    if (!mafiaMet) {
      return GameFrameZeroNightMeet(GameRole.mafia);
    }

    var sheriffSpoke = last.findAllPreceeding((frame) {
      if (frame is GameFrameZeroNightMeet) {
        return frame.roleGroup == GameRole.sheriff;
      } else {
        return false;
      }
    }).isNotEmpty;

    if (!sheriffSpoke) {
      return GameFrameZeroNightMeet(GameRole.sheriff);
    }

    var doctorSpoke =
        !hasDoctor ||
        last.findAllPreceeding((frame) {
          if (frame is GameFrameZeroNightMeet) {
            return frame.roleGroup == GameRole.doctor;
          } else {
            return false;
          }
        }).isNotEmpty;

    if (!doctorSpoke) {
      return GameFrameZeroNightMeet(GameRole.doctor);
    }

    var killerSpoke =
        !hasKiller ||
        last.findAllPreceeding((frame) {
          if (frame is GameFrameZeroNightMeet) {
            return frame.roleGroup == GameRole.killer;
          } else {
            return false;
          }
        }).isNotEmpty;

    if (!killerSpoke) {
      return GameFrameZeroNightMeet(GameRole.killer);
    }

    return null;
  }

  static GameFrame? _votingStartFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    var allSpeechFrames = frame
        .takeAllBackwardsIncludingUntil<GameFrameDaySpeech>(
          (f) => f.dayOpening,
        );

    var playersToVoteOn = List<int>.empty(growable: true);

    for (final speechFrame in allSpeechFrames) {
      if (speechFrame.putUpForVoteIndex != null) {
        playersToVoteOn.insert(
          0,
          players[speechFrame.putUpForVoteIndex!].index,
        );
      }
    }

    if (playersToVoteOn.length > 1) {
      return GameFrameDayVotingStart(playersToVoteOn, []);
    } else {
      return null;
    }
  }

  static GameFrame? _nextVotingSpeechFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    var voteStartFrame = frame.firstBackwards<GameFrameDayVotingStart>();
    if (voteStartFrame == null) return null;

    var playersToVoteOn = voteStartFrame.indexes;
    var allVoteSpeechFrames = frame
        .takeBackUntil<GameFrameDayPlayerVotingSpeech>(voteStartFrame);

    for (final playerIndex in playersToVoteOn) {
      if (allVoteSpeechFrames.any((f) => f.index == playerIndex)) continue;
      return GameFrameDayPlayerVotingSpeech(playerIndex);
    }

    return null;
  }

  static GameFrame? _nextVotingFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    var voteStartFrame = frame.firstBackwards<GameFrameDayVotingStart>();
    if (voteStartFrame == null) return null;

    var playersToVoteOn = voteStartFrame.indexes;
    var allVotingFrames = frame.takeBackUntil<GameFrameDayVoteOnPlayerLeaving>(
      voteStartFrame,
    );

    for (final player in playersToVoteOn) {
      if (allVotingFrames.any((f) => f.playerToVoteFor == player)) continue;
      return GameFrameDayVoteOnPlayerLeaving(player);
    }

    if (allVotingFrames.isNotEmpty) {
      int maxVotes = allVotingFrames.fold(
        0,
        (value, frame) => frame.voteCount >= value ? frame.voteCount : value,
      );

      final voteWinners = allVotingFrames
          .where((f) => f.voteCount >= maxVotes)
          .map((f) => f.playerToVoteFor)
          .toList()
          .reversed
          .toList();

      assert(voteWinners.isNotEmpty);
      if (voteWinners.length == 1) {
        return GameFrameDayPlayersVotedOut(voteWinners.reversed.toList());
      } else if (listEquals(voteStartFrame.indexes, voteWinners) &&
          voteStartFrame.previousVoteIndexes.isNotEmpty) {
        return GameFrameDayVoteOnAllLeaving(voteWinners.toList());
      } else {
        return GameFrameDayVotingStart(
          voteWinners.toList(),
          voteStartFrame.indexes,
        );
      }
    }

    return null;
  }

  static GameFrame? _allLeavingResultFrame(
    GameFrameDayVoteOnAllLeaving frame,
    List<GamePlayer> players,
  ) {
    final leaveAmount = frame.playersToVoteFor.length;
    final votingPlayers = players.whereAlive().length - leaveAmount;
    if (frame.voteCount > votingPlayers / 2) {
      return GameFrameDayPlayersVotedOut(frame.playersToVoteFor);
    } else {
      return null;
    }
  }

  static GameFrame? _nextNightFrame(GameFrame frame, List<GamePlayer> players) {
    var nightStart = frame.firstBackwards<GameFrameNightStart>();
    var actionFrames = frame.takeBackUntil<GameFrameNightRoleAction>(
      nightStart!,
    );

    if (players.whereRole(GameRole.priest).isNotEmpty &&
        !actionFrames.any((f) => f.role == GameRole.priest)) {
      return GameFrameNightRoleAction(GameRole.priest);
    }

    if (!actionFrames.any((f) => f.role == GameRole.mafia)) {
      return GameFrameNightRoleAction(GameRole.mafia);
    }

    if (players.whereRole(GameRole.don).isNotEmpty &&
        !actionFrames.any((f) => f.role == GameRole.don)) {
      return GameFrameNightRoleAction(GameRole.don);
    }

    if (players.whereRole(GameRole.sheriff).isNotEmpty &&
        !actionFrames.any((f) => f.role == GameRole.sheriff)) {
      return GameFrameNightRoleAction(GameRole.sheriff);
    }

    if (players.whereRole(GameRole.doctor).isNotEmpty &&
        !actionFrames.any((f) => f.role == GameRole.doctor)) {
      return GameFrameNightRoleAction(GameRole.doctor);
    }

    if (players.whereRole(GameRole.killer).isNotEmpty &&
        !actionFrames.any((f) => f.role == GameRole.killer)) {
      return GameFrameNightRoleAction(GameRole.killer);
    }

    return null;
  }

  static GameResult checkForGameEnd(
    GameFrame last,
    Iterable<GamePlayer> players,
  ) {
    switch (last) {
      case GameFrameStart _:
      case GameFrameAddPlayers _:
      case GameFrameAssignRole _:
      case GameFrameZeroNightStart _:
        return GameResult.none;
    }

    int playerCount = players.whereAlive().length;
    int killerCount = players.killers.whereAlive().length;
    int mafiaCount = players.mafiosi.whereAlive().length;
    int civilianCount = players.civilians.whereAlive().length;
    int priestCount = players.whereRole(GameRole.priest).whereAlive().length;

    if (playerCount == 2 &&
        killerCount == 1 &&
        (priestCount == 1 || civilianCount == 1)) {
      // killer vs priest
      return GameResult.killerWon;
    } else if (playerCount == 2 &&
        killerCount == 1 &&
        mafiaCount == 1 &&
        priestCount == 0) {
      // killer-mafia draw (non-priest)
      return GameResult.killerMafiaDraw;
    } else if (mafiaCount >=
        civilianCount + killerCount + (killerCount > 0 ? 1 : 0)) {
      // more mafia than civilians & killers (+1 if there are still killers around)
      return GameResult.mafiaWon;
    } else if (mafiaCount == 0 && killerCount == 0) {
      // no mafia or killer
      return GameResult.civiliansWon;
    }

    return GameResult.none;
  }
}
