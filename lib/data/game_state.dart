import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/ui/game/game_screen.dart';

import 'game_frame_tree.dart';

class GameState {
  const GameState(
    this.rootFrame,
    this.frameCount,
    this.frameIndex,
    this.lastFrame,
    this.gameResult,
    this.nextFrame,
    this.players,
    this.voteMap,
    this.priestBlockedPlayer,
    this.playersUpForVote,
  );

  final GameFrame rootFrame;
  final int frameCount;
  final int frameIndex;
  final GameFrame lastFrame;
  final GameFrame? nextFrame;
  final GameResult gameResult;
  final List<GamePlayer> players;
  final Map<int, List<int>> voteMap;
  final GamePlayer? priestBlockedPlayer;
  final List<GamePlayer?> playersUpForVote;

  int get aliveCount => players.where((p) => p.alive).length;
  int get aliveCivilianCount => players.civilians.where((p) => p.alive).length;
  int get mafiaCount => players.mafiosi.where((p) => p.alive).length;
  int get killerCount => players.killers.where((p) => p.alive).length;

  static GameState calculate(GameFrame lastFrame) {
    var players = List<GamePlayer>.empty(growable: true);
    var playersUpForVote = <GamePlayer>[];
    Map<int, List<int>> voteMap = {};
    int? priestTarget;

    var rootFrame = lastFrame.findFirst();
    GameFrame? frame = rootFrame;
    while (frame != null) {
      switch (frame) {
        case GameFrameAddPlayers addPlayersFrame:
          players.addAll(
            addPlayersFrame.players.indexed.map(
              (kv) => GamePlayer(kv.$1, kv.$2),
            ),
          );
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

        case GameFrameDayPlayersVotedOut votedOutFrame:
          for (final index in votedOutFrame.playersVotedOut) {
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

        case GameFrameDayVoteOnPlayerLeaving voteFrame:
          voteMap[voteFrame.playerToVoteFor] = voteFrame.votes;
          break;

        case GameFrameDayVoteOnAllLeaving voteFrame:
          voteMap[-1] = voteFrame.votes;
          break;

        case GameFrameNightStart _:
          priestTarget = null;
          playersUpForVote.clear();
          break;

        case GameFrameNightRoleAction frame:
          if (frame.role == GameRole.priest) {
            priestTarget = frame.index;
          }
          break;

        case GameFrameDayFarewellSpeech frame:
          players[frame.index].alive = false;
          break;
      }

      if (frame == lastFrame) break;
      frame = frame.next;
    }

    final nextFrame = _createNextFrame(lastFrame, players);
    var gameEndResult = GameState.checkForGameEnd(lastFrame, players);

    return GameState(
      rootFrame,
      rootFrame.countNext(),
      lastFrame.countPrevious(),
      lastFrame,
      gameEndResult,
      nextFrame,
      players,
      voteMap,
      priestTarget != null ? players[priestTarget] : null,
      playersUpForVote,
    );
  }

  static GameFrame? _createNextFrame(GameFrame last, List<GamePlayer> players) {
    GameFrame? next;
    switch (last) {
      case GameFrameStart _:
        next = GameFrameAddPlayers();
        break;

      case GameFrameAssignRole _:
      case GameFrameAddPlayers _:
        var unassigned = players.where((p) => p.role == GameRole.none);
        if (unassigned.isNotEmpty) {
          next = GameFrameAssignRole(unassigned.first.index);
        } else {
          next = _nextZeroNightMeetFrame(last, players);
          assert(next != null);
        }
        break;

      case GameFrameZeroNightMeet _:
        next =
            _nextZeroNightMeetFrame(last, players) ??
            GameFrameDaySpeech(players.first.index, true);
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
        next = _nextVotingSpeechFrame(frame, players)!;
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

      case GameFrameDayPlayersVotedOut frame:
        next = GameFrameNightStart();
        break;

      case GameFrameNightStart frame:
        next =
            _nextNightFrame(frame, players) ??
            _nextFarewellFrame(frame, players) ??
            _firstDayFrame(frame, players);
        break;

      case GameFrameNightRoleAction frame:
        next =
            _nextNightFrame(frame, players) ??
            _nextFarewellFrame(frame, players) ??
            _firstDayFrame(frame, players);
        break;

      case GameFrameDayFarewellSpeech frame:
        next =
            _nextFarewellFrame(frame, players) ??
            _firstDayFrame(frame, players);
        break;
    }

    if (next == null) return null;
    next.previous = last;
    return next;
  }

  static GameFrame _firstDayFrame(GameFrame frame, List<GamePlayer> players) {
    final lastFirstSpeechFrame = frame.findBackwards<GameFrameDaySpeech>(
      (f) => f.dayOpening,
    );

    if (lastFirstSpeechFrame == null) {
      return GameFrameDaySpeech(players.first.index, true);
    } else {
      var nextPlayer = players.findNextAlive(lastFirstSpeechFrame.index);
      return GameFrameDaySpeech(nextPlayer.index, true);
    }
  }

  static GameFrame? _nextFarewellFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    final nightStart = frame.firstBackwards<GameFrameNightStart>();

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

    final farewellFrames = frame.takeBackUntil<GameFrameDayFarewellSpeech>(
      nightStart,
    );

    for (final index in killedIndices) {
      if (!farewellFrames.any((f) => f.index == index)) {
        return GameFrameDayFarewellSpeech(index);
      }
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
  }

  static GameResult checkForGameEnd(
    GameFrame last,
    Iterable<GamePlayer> players,
  ) {
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
