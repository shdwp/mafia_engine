import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:uuid/uuid.dart';

abstract class GameFrame {
  GameFrame() : id = Uuid().v4().substring(0, 6), time = DateTime.now();
  Map<String, dynamic> toJson() => {
    "id": id,
    "time": time.millisecondsSinceEpoch,
    "type": runtimeType.toString(),
    "previous": previous?.id,
    "next": next?.id,
    "dirty": dirty,
  };

  String id;
  DateTime time;
  GameFrame? previous;
  GameFrame? next;

  bool dirty = true;

  bool get isDirty => dirty;
  bool get isValid => true;
}

class GameFrameStart extends GameFrame {
  GameFrameStart()
    : gameName = GameRepository.newGameName(),
      fileName = GameRepository.newSaveGameFileName(),
      dateTime = DateTime.now();

  GameFrameStart.fromJson(GameLoadState state)
    : gameName = state.get("gameName"),
      fileName = state.get("fileName"),
      dateTime = DateTime.fromMillisecondsSinceEpoch(state.get("dateTime"));

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "gameName": gameName,
      "fileName": fileName,
      "dateTime": dateTime.millisecondsSinceEpoch,
    });
    return dict;
  }

  String fileName;
  String gameName;
  DateTime dateTime;
}

class GameFrameAddPlayers extends GameFrame {
  GameFrameAddPlayers();
  GameFrameAddPlayers.fromJson(GameLoadState state)
    : players = state.getList("players"),
      roles = state
          .getList("roles")
          .map((e) => GameRole.values.byName(e))
          .toList();

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "players": players,
      "roles": roles.map((e) => e.name).toList(),
    });
    return dict;
  }

  List<String> players = List.filled(10, "", growable: true);
  List<GameRole> roles = <GameRole>[
    GameRole.civilian,
    GameRole.mafia,
    GameRole.don,
    GameRole.sheriff,
  ];
}

class GameFrameZeroNightStart extends GameFrame {
  GameFrameZeroNightStart();
  GameFrameZeroNightStart.fromJson(GameLoadState state);
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

class GameFrameDayStart extends GameFrame {
  GameFrameDayStart();
  GameFrameDayStart.fromJson(GameLoadState state);
}

class GameFrameDayFarewellSpeech extends GameFrame {
  GameFrameDayFarewellSpeech(this.playersKilled, this.firstNight) {
    for (final _ in playersKilled) {
      firstNightGuesses.add([]);
    }
  }

  GameFrameDayFarewellSpeech.fromJson(GameLoadState state)
    : playersKilled = state.getList("playersKilled"),
      firstNight = state.get("firstNight") {
    for (final kv in playersKilled.indexed) {
      firstNightGuesses.add(state.getList("firstNightGuess_${kv.$1}"));
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({"playersKilled": playersKilled, "firstNight": firstNight});

    for (final kv in playersKilled.indexed) {
      dict["firstNightGuess_${kv.$1}"] = firstNightGuesses[kv.$1];
    }
    return dict;
  }

  final List<int> playersKilled;
  List<List<int>> firstNightGuesses = [];
  final bool firstNight;
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

enum GameFrameNarratorStateOverrideType { dayStart, nightStart }

class GameFrameNarratorStateOverride extends GameFrame {
  GameFrameNarratorStateOverride(this.type, this.players);
  GameFrameNarratorStateOverride.fromJson(GameLoadState state)
    : type = GameFrameNarratorStateOverrideType.values.byName(
        state.get("overrideType"),
      ),
      firstToTalk = state.get("firstToTalk") {
    var list = List<(String, GameRole, bool, int)>.empty(growable: true);
    for (var i = 0; i < state.get<int>("playerCount"); i++) {
      var key = "player_$i";
      list.add((
        state.get("${key}_name"),
        GameRole.values.byName(state.get("${key}_role")),
        state.get("${key}_alive"),
        state.get("${key}_penalties"),
      ));
    }

    players = list;
  }

  @override
  Map<String, dynamic> toJson() {
    var dict = super.toJson();
    dict.addAll({
      "overrideType": type.name,
      "firstToTalk": firstToTalk,
      "playerCount": players.length,
    });
    for (final kv in players.indexed) {
      dict["player_${kv.$1}_name"] = kv.$2.$1;
      dict["player_${kv.$1}_role"] = kv.$2.$2.name;
      dict["player_${kv.$1}_alive"] = kv.$2.$3;
      dict["player_${kv.$1}_penalties"] = kv.$2.$4;
    }
    return dict;
  }

  GameFrameNarratorStateOverrideType type;
  int? firstToTalk;
  late final List<(String, GameRole, bool, int)> players;
}

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
