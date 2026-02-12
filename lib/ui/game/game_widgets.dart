import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';

class GameUILib {}

class GamePlayerSelectorViewModel {
  GamePlayerSelectorViewModel(this.player, this.available, this.selected);

  final GamePlayer player;
  bool available;
  bool selected;
}

enum GamePlayerSelectorOrientation { topLeft, bottomRight }

class GamePlayerSelectorWidget extends StatelessWidget {
  const GamePlayerSelectorWidget({
    super.key,
    required this.players,
    required this.onPress,
    this.showRoles = false,
  });

  final Iterable<GamePlayerSelectorViewModel> players;
  final Function(int index) onPress;
  final bool showRoles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      children: List.generate(players.length, (index) {
        final element = players.elementAt(index);
        final onPressed = !element.available ? null : () => onPress(index);
        final String text =
            "${element.player.alive ? "" : "💀"}${element.player.seatName}";

        Widget child;
        if (showRoles) {
          child = GamePlayerRoleWidget(
            role: element.player.role,
            textOverride: text,
          );
        } else {
          child = Text(text);
        }

        if (element.selected) {
          return FilledButton(onPressed: onPressed, child: child);
        } else {
          return ElevatedButton(onPressed: onPressed, child: child);
        }
      }),
    );
  }
}

class GamePlayerSetRoleViewModel {
  GamePlayerSetRoleViewModel(this.roles);

  final List<GameRole> roles;
}

class GamePlayerCycleRoleWidget extends StatelessWidget {
  const GamePlayerCycleRoleWidget({
    super.key,
    required this.viewModel,
    required this.onPress,
  });

  final GamePlayerSetRoleViewModel viewModel;
  final Function(GameRole role) onPress;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (final role in viewModel.roles) {
      children.add(
        ElevatedButton(
          onPressed: () => onPress,
          child: GamePlayerRoleWidget(role: role),
        ),
      );
    }

    return Row(children: children);
  }
}

class GamePlayerRoleWidget extends StatelessWidget {
  const GamePlayerRoleWidget({
    super.key,
    required this.role,
    this.enabled = true,
    this.textOverride = "",
  });

  final GameRole role;
  final bool enabled;
  final String textOverride;

  @override
  Widget build(BuildContext context) {
    String name;
    Color background, foreground;

    switch (role) {
      case GameRole.civilian:
        name = "Ц";
        background = Colors.red;
        foreground = Colors.black;
        break;
      case GameRole.mafia:
        name = "M";
        background = Colors.black;
        foreground = Colors.white;
        break;
      case GameRole.don:
        name = "Д";
        background = Colors.black;
        foreground = Colors.pink;
        break;
      case GameRole.priest:
        name = "С";
        background = Colors.black;
        foreground = Colors.yellow;
        break;
      case GameRole.sheriff:
        name = "Ш";
        background = Colors.green;
        foreground = Colors.black;
        break;
      case GameRole.doctor:
        name = "Л";
        background = Colors.blue;
        foreground = Colors.black;
        break;
      case GameRole.killer:
        name = "K";
        background = Colors.yellow;
        foreground = Colors.black;
        break;
      default:
        name = "?";
        background = Colors.grey;
        foreground = Colors.black;
        break;
    }

    if (!enabled) background = Colors.grey;
    return CircleAvatar(
      radius: 20,
      backgroundColor: background,
      child: Text(
        textOverride.isNotEmpty ? textOverride : name,
        style: TextStyle(color: foreground),
      ),
    );
  }
}

class GameResultWidget extends StatelessWidget {
  const GameResultWidget({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    String text = "";
    Color background = Colors.white, foreground = Colors.black;

    switch (result) {
      case GameResult.none:
        break;
      case GameResult.killerWon:
        text = "Killer won!";
        background = Colors.yellow;
        foreground = Colors.black;
        break;

      case GameResult.mafiaWon:
        text = "Mafia won!";
        background = Colors.black;
        foreground = Colors.white;
        break;

      case GameResult.civiliansWon:
        text = "Civilians won!";
        background = Colors.red;
        foreground = Colors.black;
        break;

      case GameResult.killerMafiaDraw:
        text = "Mafia/killer draw!";
        background = Colors.black;
        foreground = Colors.yellow;
        break;
    }

    if (text.isEmpty) {
      return Row();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(text, style: TextStyle(color: foreground)),
      ),
    );
  }
}
