import 'dart:core';

import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';

class GameState {
  const GameState(
    this.rootFrame,
    this.frameCount,
    this.frameIndex,
    this.lastFrame,
    this.gameFinished,
    this.nextFrame,
    this.players,
  );

  final GameFrame rootFrame;
  final int frameCount;
  final int frameIndex;
  final GameFrame lastFrame;
  final GameFrame? nextFrame;
  final bool gameFinished;
  final List<GamePlayer> players;

  int get aliveCount => players.where((p) => p.alive).length;
  int get aliveCivilianCount => players.civilians.where((p) => p.alive).length;
  int get mafiaCount => players.mafiosi.where((p) => p.alive).length;
  int get killerCount => players.killers.where((p) => p.alive).length;

  static GameState calculate(GameFrame lastFrame) {
    var gameFinished = false;
    var players = List<GamePlayer>.empty(growable: true);

    var rootFrame = lastFrame.findFirst();
    GameFrame? frame = rootFrame;
    while (frame != null) {
      switch (frame) {
        case GameFrameAddPlayers addPlayersFrame:
          players.addAll(
            addPlayersFrame.players.indexed.map(
              (kv) => GamePlayer(kv.$1, kv.$2, GameRole.none, true),
            ),
          );
          break;

        case GameFrameAssignRole assignRoleFrame:
          var player = assignRoleFrame.player;
          players[player.index] = GamePlayer(
            player.index,
            player.name,
            assignRoleFrame.role,
            true,
          );
          break;

        case GameFrameDayPlayersVotedOut votedOutFrame:
          for (final player in votedOutFrame.playersVotedOut) {
            players[player.index] = GamePlayer(
              player.index,
              player.name,
              player.role,
              false,
            );
          }
          break;
      }

      if (frame == lastFrame) break;
      frame = frame.next;
    }

    final nextFrame = _createNextFrame(lastFrame, players);
    return GameState(
      rootFrame,
      rootFrame.countNext(),
      lastFrame.countPrevious(),
      lastFrame,
      gameFinished,
      nextFrame,
      players,
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
          next = GameFrameAssignRole(unassigned.first);
        } else {
          next = _nextZeroNightMeetFrame(last, players);
          assert(next != null);
        }
        break;

      case GameFrameZeroNightMeet _:
        next =
            _nextZeroNightMeetFrame(last, players) ??
            _checkForGameEnd(last, players) ??
            GameFrameDaySpeech(players.first, true);
        break;

      case GameFrameDaySpeech frame:
        var allSpeechFrames = frame
            .takeAllBackwardsIncludingUntil<GameFrameDaySpeech>(
              (f) => f.dayOpening,
            );
        var nextPlayer = players.findNextAlive(frame.player.index);
        if (nextPlayer == allSpeechFrames.last.player) {
          next =
              _votingStartFrame(frame, players) ??
              _firstNightFrame(frame, players);
        } else {
          next = GameFrameDaySpeech(nextPlayer, false);
        }
        break;

      case GameFrameDayVotingStart frame:
        next = _nextVotingSpeechFrame(frame, players)!;
        break;

      case GameFrameDayPlayerVotingSpeech frame:
        next =
            _nextVotingSpeechFrame(frame, players) ??
            _nextVotingFrame(frame, players) ??
            _firstNightFrame(frame, players);
        break;

      case GameFrameDayVoteOn frame:
        next =
            _nextVotingFrame(frame, players) ??
            _firstNightFrame(frame, players);
        break;

      case GameFrameDayPlayersVotedOut frame:
        next = _firstNightFrame(frame, players);
        break;
    }

    if (next == null) return null;
    next.previous = last;
    return next;
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

    var playersToVoteOn = List<GamePlayer>.empty(growable: true);

    for (final speechFrame in allSpeechFrames) {
      if (speechFrame.putUpForVoteIndex != null) {
        playersToVoteOn.insert(0, players[speechFrame.putUpForVoteIndex!]);
      }
    }

    if (playersToVoteOn.isNotEmpty) {
      return GameFrameDayVotingStart(playersToVoteOn);
    } else {
      return null;
    }
  }

  static GameFrame? _nextVotingSpeechFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    var voteStartFrame = frame.findBackwards<GameFrameDayVotingStart>();
    if (voteStartFrame == null) return null;

    var playersToVoteOn = voteStartFrame.players;
    var allVoteSpeechFrames = voteStartFrame
        .takeAllForwards<GameFrameDayPlayerVotingSpeech>();

    for (final player in playersToVoteOn) {
      if (allVoteSpeechFrames.any((f) => f.player == player)) continue;
      return GameFrameDayPlayerVotingSpeech(player);
    }

    return null;
  }

  static GameFrame? _nextVotingFrame(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    var voteStartFrame = frame.findBackwards<GameFrameDayVotingStart>();
    if (voteStartFrame == null) return null;

    var playersToVoteOn = voteStartFrame.players;
    var allVotingFrames = voteStartFrame.takeAllForwards<GameFrameDayVoteOn>();

    for (final player in playersToVoteOn) {
      if (allVotingFrames.any((f) => f.playerToVoteFor == player)) continue;
      return GameFrameDayVoteOn(player);
    }

    if (allVotingFrames.isNotEmpty) {
      int maxVotes = allVotingFrames.fold(
        0,
        (value, frame) => frame.voteCount >= value ? frame.voteCount : value,
      );

      final voteWinners = allVotingFrames
          .where((f) => f.voteCount >= maxVotes)
          .map((f) => f.playerToVoteFor);

      assert(voteWinners.isNotEmpty);
      if (voteWinners.length == 1) {
        return GameFrameDayPlayersVotedOut(voteWinners.toList());
      } else {
        return GameFrameDayVotingStart(voteWinners.toList());
      }
    }

    return null;
  }

  static GameFrame _firstNightFrame(GameFrame frame, List<GamePlayer> players) {
    return GameFrameNightPriestAction();
  }

  static GameFrame? _checkForGameEnd(
    GameFrame last,
    Iterable<GamePlayer> players,
  ) {
    int playerCount = players.whereAlive().length;
    int killerCount = players.killers.length;
    int mafiaCount = players.mafiosi.length;
    int civilianCount = players.civilians.length;
    int priestCount = players.whereRole(GameRole.priest).length;

    if (playerCount == 2 &&
        killerCount == 1 &&
        (priestCount == 1 || civilianCount == 1)) {
      // killer vs priest
      return GameFrameEnd(GameResult.killerWon);
    } else if (playerCount == 2 &&
        killerCount == 1 &&
        mafiaCount == 1 &&
        priestCount == 0) {
      // killer-mafia draw (non-priest)
      return GameFrameEnd(GameResult.killerMafiaDraw);
    } else if (mafiaCount >=
        civilianCount + killerCount + (killerCount > 0 ? 1 : 0)) {
      // more mafia than civilians & killers (+1 if there are still killers around)
      return GameFrameEnd(GameResult.mafiaWon);
    } else if (mafiaCount == 0 && killerCount == 0) {
      // no mafia or killer
      return GameFrameEnd(GameResult.civiliansWon);
    }

    return null;
  }
}
