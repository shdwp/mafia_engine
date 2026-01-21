enum GameRole { none, civilian, mafia, don, priest, sheriff, doctor, killer }

// TODO
enum GameRoleGroup { none, civilian, mafia, killer }

enum GameResult { none, killerWon, mafiaWon, civiliansWon, killerMafiaDraw }

extension GameRoleColorExtension on GameRole {
  bool get isCivilian {
    switch (this) {
      case GameRole.civilian:
        return true;
      case GameRole.sheriff:
        return true;
      case GameRole.doctor:
        return true;
      default:
        return false;
    }
  }

  bool get isMafia {
    switch (this) {
      case GameRole.mafia:
        return true;
      case GameRole.don:
        return true;
      case GameRole.priest:
        return true;
      default:
        return false;
    }
  }

  bool get isKiller {
    switch (this) {
      case GameRole.killer:
        return true;
      default:
        return false;
    }
  }
}

extension PlayerListFilters on Iterable<GamePlayer> {
  Iterable<GamePlayer> get civilians => where((p) => p.role.isCivilian);
  Iterable<GamePlayer> get mafiosi => where((p) => p.role.isMafia);
  Iterable<GamePlayer> get killers => where((p) => p.role.isKiller);

  Iterable<GamePlayer> whereRole(GameRole role) => where((p) => p.role == role);
  Iterable<GamePlayer> whereAlive() => where((p) => p.alive);

  GamePlayer findNextAlive(int index) {
    GamePlayer? result;

    var count = 0;
    index++;
    while (count <= length) {
      if (length <= index) index = 0;
      var player = this.elementAt(index);
      if (player.alive) {
        result = player;
        break;
      }

      index++;
      count++;
    }

    return result!;
  }
}

class GamePlayer {
  const GamePlayer(this.index, this.name, this.role, this.alive);
  @override
  bool operator ==(Object other) => other is GamePlayer && other.index == index;
  @override
  int get hashCode => index;

  final int index;
  String get seatName => (index + 1).toString();
  final String name;
  final GameRole role;
  final bool alive;
}
