import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:uuid/uuid.dart';

abstract class GameFrame {
  GameFrame() : id = Uuid().v4().substring(0, 6);
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": runtimeType.toString(),
    "previous": previous?.id,
    "next": next?.id,
    "dirty": dirty,
  };

  String id;
  GameFrame? previous;
  GameFrame? next;

  bool dirty = true;

  bool get isDirty => dirty;
  bool get isValid => true;
}

class GameFrameStart extends GameFrame {}

class GameFrameNarratorPenalize extends GameFrame {
  GameFrameNarratorPenalize();
  GameFrameNarratorPenalize.fromJson(GameLoadState state)
    : index = state.get("index"),
      amount = state.get("amount");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"index": index, "amount": amount});
    return dict;
  }

  @override
  bool get isDirty => false;

  int? index;
  int amount = 0;
}

class GameFrameAddPlayers extends GameFrame {
  GameFrameAddPlayers();
  GameFrameAddPlayers.fromJson(GameLoadState state)
    : players = state.getList("players");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"players": players});
    return dict;
  }

  List<String> players = List.filled(10, "Unnamed", growable: true);
}

class GameFrameAssignRole extends GameFrame {
  GameFrameAssignRole(this.index);
  GameFrameAssignRole.fromJson(GameLoadState state)
    : index = state.get("index"),
      role = GameRole.values.byName(state.get("role"));

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"index": index, "role": role.name});
    return dict;
  }

  @override
  bool get isValid => role != GameRole.none;

  final int index;
  GameRole role = GameRole.none;
}

class GameFrameZeroNightMeet extends GameFrame {
  GameFrameZeroNightMeet(this.roleGroup);
  GameFrameZeroNightMeet.fromJson(GameLoadState state)
    : roleGroup = GameRole.values.byName(state.get("roleGroup"));

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"roleGroup": roleGroup.name});
    return dict;
  }

  final GameRole roleGroup;
}

class GameFrameDaySpeech extends GameFrame {
  GameFrameDaySpeech(this.index, this.dayOpening);
  GameFrameDaySpeech.fromJson(GameLoadState state)
    : index = state.get("index"),
      dayOpening = state.get("dayOpening"),
      putUpForVoteIndex = state.get("putUpForVoteIndex");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "index": index,
      "dayOpening": dayOpening,
      "putUpForVoteIndex": putUpForVoteIndex,
    });
    return dict;
  }

  final int index;
  final bool dayOpening;
  int? putUpForVoteIndex;
}

class GameFrameDayVotingStart extends GameFrame {
  GameFrameDayVotingStart(this.indexes, this.previousVoteIndexes);
  GameFrameDayVotingStart.fromJson(GameLoadState state)
    : indexes = state.getList("playerIndexes"),
      previousVoteIndexes = state.getList("previousVoteIndexes");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "playerIndexes": indexes,
      "previousVoteIndexes": previousVoteIndexes,
    });
    return dict;
  }

  final List<int> indexes;
  final List<int> previousVoteIndexes;
}

class GameFrameDayPlayerVotingSpeech extends GameFrame {
  GameFrameDayPlayerVotingSpeech(this.index);
  GameFrameDayPlayerVotingSpeech.fromJson(GameLoadState state)
    : index = state.get("index");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"index": index});
    return dict;
  }

  final int index;
}

class GameFrameDayVoteOnPlayerLeaving extends GameFrame {
  GameFrameDayVoteOnPlayerLeaving(this.playerToVoteFor);
  GameFrameDayVoteOnPlayerLeaving.fromJson(GameLoadState state)
    : playerToVoteFor = state.get("playerIndex"),
      votes = state.getList("voteIndexes");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndex": playerToVoteFor, "voteIndexes": votes});
    return dict;
  }

  int get voteCount => votes.length;

  final int playerToVoteFor;
  List<int> votes = List.empty(growable: true);
}

class GameFrameDayVoteOnAllLeaving extends GameFrame {
  GameFrameDayVoteOnAllLeaving(this.playersToVoteFor);
  GameFrameDayVoteOnAllLeaving.fromJson(GameLoadState state)
    : playersToVoteFor = state.getList("playerIndexes"),
      votes = state.getList("voteIndexes");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndexes": playersToVoteFor, "voteIndexes": votes});
    return dict;
  }

  final List<int> playersToVoteFor;
  List<int> votes = List.empty(growable: true);
  int get voteCount => votes.length;
}

class GameFrameDayPlayersVotedOut extends GameFrame {
  GameFrameDayPlayersVotedOut(this.playersVotedOut);
  GameFrameDayPlayersVotedOut.fromJson(GameLoadState state)
    : playersVotedOut = state.getList("playerIndexes");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playerIndexes": playersVotedOut});
    return dict;
  }

  final List<int> playersVotedOut;
}

class GameFrameNightStart extends GameFrame {
  GameFrameNightStart();
  GameFrameNightStart.fromJson(GameLoadState state);
}

class GameFrameDayFarewellSpeech extends GameFrame {
  GameFrameDayFarewellSpeech(this.index);
  GameFrameDayFarewellSpeech.fromJson(GameLoadState state)
    : index = state.get("index");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"index": index});
    return dict;
  }

  final int index;
}

class GameFrameNightRoleAction extends GameFrame {
  GameFrameNightRoleAction(this.role);
  GameFrameNightRoleAction.fromJson(GameLoadState state)
    : role = GameRole.values.byName(state.get("role")),
      index = state.get("index");

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"index": index, "role": role.name});
    return dict;
  }

  final GameRole role;
  int? index;
}
