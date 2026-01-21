import 'package:async/async.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:uuid/uuid.dart';

extension GameTree on GameFrame {
  Iterable<GameFrame> findAllPreceeding(bool Function(GameFrame x) predicate) {
    var result = List<GameFrame>.empty(growable: true);
    var frame = this;
    if (predicate(frame)) result.add(frame);

    while (frame.previous != null) {
      frame = frame.previous!;
      if (predicate(frame)) result.add(frame);
    }
    return result;
  }

  Iterable<T> takeAllBackwardsIncludingUntil<T extends GameFrame>(
    bool Function(T frame) predicate,
  ) {
    var result = List<T>.empty(growable: true);
    var frame = this;

    if (frame is T) {
      result.add(frame);
      if (predicate(frame)) return result;
    }

    while (frame.previous != null) {
      frame = frame.previous!;

      if (frame is T) {
        result.add(frame);
        if (predicate(frame)) return result;
      }
    }
    return result;
  }

  Iterable<T> takeAllForwards<T extends GameFrame>() {
    var result = List<T>.empty(growable: true);
    var frame = this;

    if (frame is T) {
      result.add(frame);
    }

    while (frame.next != null) {
      frame = frame.next!;

      if (frame is T) {
        result.add(frame);
      }
    }
    return result;
  }

  T? findBackwards<T extends GameFrame>() {
    var frame = this;
    if (frame is T) return frame;

    while (frame.previous != null) {
      frame = frame.previous!;
      if (frame is T) return frame;
    }
    return null;
  }

  GameFrame findLast() {
    var frame = this;
    while (frame.next != null) {
      frame = frame.next!;
    }
    return frame;
  }

  GameFrame findFirst() {
    var frame = this;
    while (frame.previous != null) {
      frame = frame.previous!;
    }
    return frame;
  }

  int countNext() {
    var amount = 1;
    var frame = this;
    while (frame.next != null) {
      frame = frame.next!;
      amount++;
    }
    return amount;
  }

  int countPrevious() {
    var amount = 1;
    var frame = this;
    while (frame.previous != null) {
      frame = frame.previous!;
      amount++;
    }
    return amount;
  }
}

abstract class GameFrame {
  GameFrame() : id = Uuid().v4().substring(0, 6);
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": this.runtimeType.toString(),
    "previous": previous?.id,
    "next": next?.id,
    "dirty": dirty,
  };

  String id;
  GameFrame? previous;
  GameFrame? next;

  bool dirty = true;
  bool get isValid => true;
}

class GameFrameStart extends GameFrame {
}

class GameFrameAddPlayers extends GameFrame {
  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"players": players});
    return dict;
  }

  List<String> players = List.filled(10, "Unnamed", growable: true);
}

class GameFrameAssignRole extends GameFrame {
  GameFrameAssignRole(this.player);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndex": player.index, "role": role.name});
    return dict;
  }

  @override
  bool get isValid => role != GameRole.none;

  final GamePlayer player;
  GameRole role = GameRole.none;
}

class GameFrameZeroNightMeet extends GameFrame {
  GameFrameZeroNightMeet(this.roleGroup);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"roleGroup": roleGroup.name});
    return dict;
  }

  final GameRole roleGroup;
}

class GameFrameDaySpeech extends GameFrame {
  GameFrameDaySpeech(this.player, this.dayOpening);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "playerIndex": player.index,
      "dayOpening": dayOpening,
      "putUpForVoteIndex": putUpForVoteIndex,
    });
    return dict;
  }

  final GamePlayer player;
  final bool dayOpening;
  int? putUpForVoteIndex;
}

class GameFrameDayVotingStart extends GameFrame {
  GameFrameDayVotingStart(this.players);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndexes": players.map((p) => p.index).toList()});
    return dict;
  }

  final List<GamePlayer> players;
}

class GameFrameDayPlayerVotingSpeech extends GameFrame {
  GameFrameDayPlayerVotingSpeech(this.player);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndex": player.index});
    return dict;
  }

  final GamePlayer player;
}

class GameFrameDayVoteOn extends GameFrame {
  GameFrameDayVoteOn(this.playerToVoteFor);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "playerIndex": playerToVoteFor.index,
      "voteIndexes": votes.map((v) => v.index).toList(),
    });
    return dict;
  }

  final GamePlayer playerToVoteFor;
  List<GamePlayer> votes = List.empty(growable: true);
  int get voteCount => votes.length;
}

class GameFrameDayPlayersVotedOut extends GameFrame {
  GameFrameDayPlayersVotedOut(this.playersVotedOut);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndexes": playersVotedOut.map((v) => v.index).toList()});
    return dict;
  }

  final List<GamePlayer> playersVotedOut;
}

class GameFrameNightPriestAction extends GameFrame {}

class GameFrameEnd extends GameFrame {
  GameFrameEnd(this.result);

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"result": result.name});
    return dict;
  }

  @override
  bool get isValid => false;

  final GameResult result;
}
