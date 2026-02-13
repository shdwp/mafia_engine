import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:provider/provider.dart';

class GameUIRoleViewModel {
  final String name;
  final Color foreground;
  final Color background;

  GameUIRoleViewModel(this.name, this.foreground, this.background);
}

class GameUILib {
  static String formatSeatName(GamePlayer player) =>
      "${player.seatName}${deadSuffix(player)}";
  static String formatPlayerName(GamePlayer player) => player.name;
  static String formatFullPlayerName(GamePlayer player) =>
      "${formatSeatName(player)} ${formatPlayerName(player)}";

  static String deadPrefix(GamePlayer player) => player.alive ? "" : "$deadSymbol ";
  static String deadSuffix(GamePlayer player) => player.alive ? "" : " $deadSymbol";

  static String deadSymbol = "💀";

  static GameUIRoleViewModel roleViewModel(GameRole role) {
    String name;
    Color foreground, background;
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
        foreground = Colors.white;
        break;
    }

    return GameUIRoleViewModel(name, foreground, background);
  }

  static void confirmDialogWithDuplicationOption(
    BuildContext context,
    GameFrame current,
    Function callback,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm:"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            style: ButtonStyle(),
            onPressed: () async {
              Navigator.pop(context);
              var result = await context.read<GameRepository>().duplicate(
                current,
              );

              if (result.isValue) {
                callback();
              }
            },
            child: Text("Duplicate & confirm"),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Colors.black),
              backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
            ),
            onPressed: () {
              Navigator.pop(context);
              callback();
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }
}

class GamePlayerSelectorViewModel {
  GamePlayerSelectorViewModel(
    this.player, {
    this.available = true,
    this.selected = false,
    this.highlighted = false,
  });

  final GamePlayer player;
  bool available;
  bool selected;
  bool highlighted;
}

class GamePlayerSelectorWidget extends StatelessWidget {
  const GamePlayerSelectorWidget({
    super.key,
    required this.players,
    this.onPress,
    this.showRoles = false,
  });

  final Iterable<GamePlayerSelectorViewModel> players;
  final Function(int index)? onPress;
  final bool showRoles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsetsGeometry.all(8),
      crossAxisCount: 4,
      children: List.generate(players.length, (index) {
        final element = players.elementAt(index);
        final onPressed = !element.available || onPress == null
            ? null
            : () => onPress!(index);
        final String text = GameUILib.formatSeatName(element.player);

        Widget child;
        if (showRoles) {
          child = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GamePlayerRoleWidget(
                role: element.player.role,
                textOverride: element.player.seatName,
                fontSize: 21,
              ),
              Text(
                GameUILib.deadPrefix(element.player).trim(),
                style: TextStyle(fontSize: 21),
              ),
            ],
          );
        } else {
          child = Text(
            text,
            style: TextStyle(fontSize: 21),
            softWrap: false,
            overflow: TextOverflow.fade,
          );
        }

        child = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            Text(
              GameUILib.formatPlayerName(element.player),
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                decoration: element.player.alive
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),
          ],
        );

        if (element.selected) {
          return FilledButton(onPressed: onPressed, child: child);
        } else {
          return ElevatedButton(
            onPressed: onPressed,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                element.highlighted ? Colors.lightGreenAccent : null,
              ),
            ),
            child: child,
          );
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
    this.fontSize,
  });

  final GameRole role;
  final bool enabled;
  final String textOverride;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    var roleModel = GameUILib.roleViewModel(role);
    var background = roleModel.background;

    if (!enabled) background = Colors.grey;
    return CircleAvatar(
      radius: 20,
      backgroundColor: background,
      child: Text(
        textOverride.isNotEmpty ? textOverride : roleModel.name,
        style: TextStyle(color: roleModel.foreground, fontSize: fontSize),
      ),
    );
  }
}

class GameResultWidget extends StatelessWidget {
  const GameResultWidget({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    String text;
    Color background, foreground;

    switch (result) {
      case GameResult.none:
        text = "";
        var viewModel = GameUILib.roleViewModel(GameRole.killer);
        background = viewModel.background;
        foreground = viewModel.foreground;
        break;

      case GameResult.killerWon:
        text = "Killer won!";
        var viewModel = GameUILib.roleViewModel(GameRole.killer);
        background = viewModel.background;
        foreground = viewModel.foreground;
        break;

      case GameResult.mafiaWon:
        text = "Mafia won!";
        var viewModel = GameUILib.roleViewModel(GameRole.mafia);
        background = viewModel.background;
        foreground = viewModel.foreground;
        break;

      case GameResult.civiliansWon:
        text = "Civilians won!";
        var viewModel = GameUILib.roleViewModel(GameRole.civilian);
        background = viewModel.background;
        foreground = viewModel.foreground;
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

class GamePlayerBadgeWidget extends StatelessWidget {
  final GamePlayer player;
  final bool showRole;

  const GamePlayerBadgeWidget({
    super.key,
    required this.player,
    this.showRole = false,
  });

  @override
  Widget build(BuildContext context) {
    var roleViewModel = GameUILib.roleViewModel(player.role);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: !showRole ? Colors.grey : roleViewModel.background,
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          GameUILib.formatFullPlayerName(player),
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 18,
            color: !showRole ? Colors.white : roleViewModel.foreground,
          ),
        ),
      ),
    );
  }
}

class GameTimerWidget extends StatefulWidget {
  final int timeInSeconds;

  const GameTimerWidget({super.key, required this.timeInSeconds});

  @override
  State<StatefulWidget> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimerWidget> {
  @override
  Widget build(BuildContext context) {
    var timerService = context.read<GameTimer>();
    return ListenableBuilder(
      listenable: timerService.notifier,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          IconButton.filled(
            onPressed: timerService.hasTimer
                ? () => timerService.start(widget.timeInSeconds)
                : null,
            icon: Icon(Icons.history),
          ),
          Text(timerService.formattedTime, style: TextStyle(fontSize: 24)),
          Visibility(
            visible: !timerService.hasTimer,
            child: IconButton.filled(
              onPressed: () => timerService.start(widget.timeInSeconds),
              icon: Icon(Icons.play_arrow),
            ),
          ),
          Visibility(
            visible: timerService.hasTimer,
            child: IconButton.filled(
              onPressed: () => timerService.togglePause(),
              icon: timerService.isPaused
                  ? Icon(Icons.play_arrow)
                  : Icon(Icons.pause),
            ),
          ),
        ],
      ),
    );
  }
}

class GamePlayerListWidget extends StatelessWidget {
  final Iterable<GamePlayer> players;
  final bool showRoles;
  final bool vertical;

  const GamePlayerListWidget({
    super.key,
    required this.players,
    this.showRoles = false,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> playerWidgets = [];
    for (final player in players) {
      playerWidgets.add(
        GamePlayerBadgeWidget(player: player, showRole: showRoles),
      );
    }

    return vertical
        ? Column(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: playerWidgets,
          )
        : Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: playerWidgets,
          );
  }
}

class GamePlayerCountersWidget extends StatelessWidget {
  final GameState state;

  const GamePlayerCountersWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        GamePlayerRoleWidget(
          role: GameRole.civilian,
          textOverride: state.aliveCivilianCount.toString(),
        ),
        GamePlayerRoleWidget(
          role: GameRole.mafia,
          textOverride: state.mafiaCount.toString(),
        ),
        Visibility(
          visible: state.rolesInTheGame.contains(GameRole.killer),
          child: GamePlayerRoleWidget(
            role: GameRole.killer,
            textOverride: state.killerCount.toString(),
          ),
        ),
        GamePlayerRoleWidget(
          role: GameRole.none,
          textOverride: state.aliveCount.toString(),
        ),
      ],
    );
  }
}
