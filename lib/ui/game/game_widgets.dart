import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_config.dart';
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

  static String formatPenalties(GamePlayer player) =>
      player.penalties > 0 ? " 🚨${player.penalties}" : "";

  static String penaltiesPrefix(GamePlayer player) =>
      player.penalties > 0 ? "🚨${player.penalties} " : "";

  static String deadPrefix(GamePlayer player) =>
      player.alive ? "" : "$deadSymbol ";
  static String deadSuffix(GamePlayer player) =>
      player.alive ? "" : " $deadSymbol";

  static String deadSymbol = "💀";
  static Color deadBackgroundColor = Color.fromARGB(255, 165, 0, 0);

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

  static String formatMinutesSeconds(int timeInSecond) {
    int sec = timeInSecond % 60;
    int min = (timeInSecond / 60).floor();
    String minute = min.toString().length <= 1 ? "0$min" : "$min";
    String second = sec.toString().length <= 1 ? "0$sec" : "$sec";

    return "$minute:$second";
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
  bool get alive => player.alive;
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
    this.crossAxisCount = 4,
    this.fontSize = 21,
    this.shrinkWrap = false,
  });

  final Iterable<GamePlayerSelectorViewModel> players;
  final void Function(int index)? onPress;
  final bool showRoles;
  final int crossAxisCount;
  final double fontSize;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsetsGeometry.all(8),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? NeverScrollableScrollPhysics() : null,
      crossAxisCount: crossAxisCount,
      children: List.generate(players.length, (index) {
        final element = players.elementAt(index);
        final onPressCallback = !element.available
            ? null
            : () {
                if (onPress != null) onPress!(index);
              };
        final String text = GameUILib.formatSeatName(element.player);

        Widget child;
        if (showRoles) {
          child = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GamePlayerRoleWidget(
                role: element.player.role,
                textOverride: element.player.seatName,
                fontSize: fontSize,
              ),
              Text(
                GameUILib.deadPrefix(element.player).trim(),
                style: TextStyle(fontSize: fontSize),
              ),
            ],
          );
        } else {
          child = Text(
            text,
            style: TextStyle(fontSize: fontSize),
            softWrap: false,
            overflow: TextOverflow.fade,
          );
        }

        child = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            Text(
              GameUILib.penaltiesPrefix(element.player) +
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
          return FilledButton(onPressed: onPressCallback, child: child);
        } else {
          return ElevatedButton(
            onPressed: onPressCallback,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                element.highlighted
                    ? Colors.lightGreenAccent
                    : (element.alive ? null : GameUILib.deadBackgroundColor),
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

class GameDayWidget extends StatelessWidget {
  final int day;

  const GameDayWidget({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Day $day", style: TextStyle(color: Colors.white)),
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
        text = "Town won!";
        var viewModel = GameUILib.roleViewModel(GameRole.civilian);
        background = viewModel.background;
        foreground = viewModel.foreground;
        break;

      case GameResult.killerMafiaDraw:
        text = "M/K draw!";
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
  final bool showPenalties;
  final double fontSize;

  const GamePlayerBadgeWidget({
    super.key,
    required this.player,
    this.showRole = false,
    this.showPenalties = true,
    this.fontSize = 18,
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
          GameUILib.formatFullPlayerName(player) +
              GameUILib.formatPenalties(player),
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: fontSize,
            color: !showRole ? Colors.white : roleViewModel.foreground,
          ),
        ),
      ),
    );
  }
}

class GameTimerWidget extends StatefulWidget {
  final int timeInSeconds;
  final bool playSounds;
  final bool autoStart;
  final bool autoRestart;

  const GameTimerWidget({
    super.key,
    required this.timeInSeconds,
    required this.playSounds,
    this.autoStart = true,
    this.autoRestart = false,
  });

  @override
  State<StatefulWidget> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimerWidget> {
  @override
  void initState() {
    super.initState();
    final timerService = context.read<GameTimer>();

    if (!widget.playSounds) timerService.setSoundsEnabled(false);

    if ((!timerService.hasTimer && widget.autoStart) || widget.autoRestart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        timerService.start(widget.timeInSeconds, playSounds: widget.playSounds);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var timerService = context.read<GameTimer>();
    var configService = context.read<GameConfigService>();
    return ListenableBuilder(
      listenable: timerService.notifier,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          IconButton.filled(
            onPressed: timerService.hasTimer
                ? () {
                    if (!timerService.isPaused) {
                      timerService.start(
                        widget.timeInSeconds,
                        playSounds: widget.playSounds,
                      );
                    } else {
                      timerService.stop();
                    }
                  }
                : null,
            icon: Icon(Icons.history),
          ),
          Text(timerService.formattedTime, style: TextStyle(fontSize: 24)),
          /*
          IconButton.filled(
            onPressed: timerService.hasTimer ? () => timerService.stop() : null,
            icon: Icon(Icons.stop),
          ),
		  */
          if (!timerService.hasTimer)
            IconButton.filled(
              onPressed: () => timerService.start(
                widget.timeInSeconds,
                playSounds: widget.playSounds,
              ),
              icon: Icon(Icons.play_arrow),
            ),

          if (timerService.hasTimer)
            IconButton.filled(
              onPressed: () => timerService.togglePause(),
              icon: timerService.isPaused
                  ? Icon(Icons.play_arrow)
                  : Icon(Icons.pause),
            ),

          if (configService.timerSoundVolume > 0)
            IconButton.outlined(
              onPressed: () => timerService.toggleSounds(),
              icon: timerService.soundsEnabled
                  ? Icon(Icons.volume_up)
                  : Icon(Icons.volume_off),
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
        if (state.rolesInTheGame.contains(GameRole.killer))
          GamePlayerRoleWidget(
            role: GameRole.killer,
            textOverride: state.killerCount.toString(),
          ),
        GamePlayerRoleWidget(
          role: GameRole.none,
          textOverride: state.aliveCount.toString(),
        ),
      ],
    );
  }
}

class GamePlayerTotalCountWidget extends StatelessWidget {
  final GameState state;

  const GamePlayerTotalCountWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return GamePlayerRoleWidget(
      role: GameRole.none,
      textOverride: state.aliveCount.toString(),
    );
  }
}

class GameScoresWidget extends StatelessWidget {
  final List<GameScore> scores;

  const GameScoresWidget({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsetsGeometry.all(8),
      itemCount: scores.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        var score = scores[index];
        var player = score.player;
        var decoration = player.alive ? null : TextDecoration.lineThrough;

        return Row(
          spacing: 4,
          children: [
            Text(GameUILib.formatSeatName(player)),
            Expanded(
              child: Text(
                GameUILib.penaltiesPrefix(player) +
                    GameUILib.formatPlayerName(player),
                style: TextStyle(decoration: decoration),
              ),
            ),
            GamePlayerRoleWidget(role: player.role),

            if (score.winPoints > 0) Text("${score.winPoints} (win)"),
            if (score.aliveBonusPoints > 0)
              Text("+${score.aliveBonusPoints} (alive)"),
            if (score.sheriffChecksPoints > 0)
              Text("+${score.sheriffChecksPoints} (guesses)"),
            if (score.doctorSavePoints > 0)
              Text("+${score.doctorSavePoints} (heals)"),
            if (score.priestBlockedPoints > 0)
              Text("+${score.priestBlockedPoints} (blocks)"),
            if (score.donFoundSheriffPoints > 0)
              Text("+${score.donFoundSheriffPoints} (finds)"),
            if (score.killerBonusPoints > 0)
              Text("+${score.killerBonusPoints} (kills)"),
            if (score.mafiaGuessPoints > 0)
              Text("+${score.mafiaGuessPoints} (first kill guesses)"),
            if (score.firstNightKilledPoints > 0)
              Text("+${score.firstNightKilledPoints} (first kill comp)"),

            Text("= ${score.total}"),
          ],
        );
      },
    );
  }
}
