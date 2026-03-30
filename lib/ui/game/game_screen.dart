import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mafia_engine/data/game_enums.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_frame_tree.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/ui/game/game_viewmodel.dart';
import 'package:mafia_engine/ui/game/game_widgets.dart';
import 'package:provider/provider.dart';

import 'day/game_day_widgets.dart';
import 'narrator/game_narrator_widgets.dart';
import 'night/game_night_widgets.dart';
import 'night/game_zero_night_widgets.dart';
import 'pre_game/game_pre_game_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.viewModel});
  final GameViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _GameScreenGameState();
}

class _GameScreenGameState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        Widget frameWidget = Text(
          "Error: frame ${widget.viewModel.current.runtimeType.toString} resulted in no widget!",
        );
        switch (widget.viewModel.current) {
          case GameFrameStart frame:
            frameWidget = GameStartWidget(
              viewModel: GameStartViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameNarratorPenalize frame:
            frameWidget = GameScreenNarratorPenalizeWidget(
              viewModel: GameNarratorPenalizeViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameNarratorStateOverride frame:
            frameWidget = GameScreenNarratorStateOverrideWidget(
              viewModel: GameNarratorStateOverrideViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;
          case GameFrameAddPlayers frame:
            frameWidget = GameScreenAddPlayersWidget(
              viewModel: GameAddPlayersViewModel(widget.viewModel, frame),
            );
            break;
          case GameFrameAssignRole frame:
            frameWidget = GameScreenAssignRoleWidget(
              viewModel: GameAssignRoleViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameZeroNightMeet frame:
            frameWidget = GameScreenZeroNightMeetWidget(
              viewModel: GameZeroNightMeetViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayFarewellSpeech frame:
            frameWidget = GameScreenDayFarewellSpeechWidget(
              viewModel: GameDayFarewellSpeechViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDaySpeech frame:
            frameWidget = GameScreenDaySpeechWidget(
              viewModel: GameDaySpeechViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayVotingStart frame:
            frameWidget = GameScreenDayVotingStartWidget(
              viewModel: GameDayVotingStartViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayPlayerVotingSpeech frame:
            frameWidget = GameScreenDayPlayerVotingSpeechWidget(
              viewModel: GameDayPlayerVotingSpeechViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDayVoteOnPlayerLeaving frame:
            frameWidget = GameScreenDayVoteOnWidget(
              viewModel: GameDayVoteOnViewModel(widget.viewModel, frame),
            );
            break;

          case GameFrameDayVoteOnAllLeaving frame:
            frameWidget = GameScreenDayVoteOnAllLeavingWidget(
              viewModel: GameDayVoteOnAllLeavingViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameDayPlayersVotedOut frame:
            frameWidget = GameScreenDayPlayersVotedOutWidget(
              viewModel: GameDayPlayersVotedOutViewModel(
                widget.viewModel,
                frame,
              ),
            );
            break;

          case GameFrameNightStart frame:
            frameWidget = GameScreenNightStartWidget(
              viewModel: GameNightStartViewModel(
                widget.viewModel,
                frame,
                context.read(),
              ),
            );
            break;

          case GameFrameZeroNightStart frame:
            frameWidget = GameScreenNightStartWidget(
              viewModel: GameNightStartViewModel(
                widget.viewModel,
                frame,
                context.read(),
              ),
            );
            break;

          case GameFrameDayStart frame:
            frameWidget = GameScreenDayStartWidget(
              viewModel: GameDayStartViewModel(
                widget.viewModel,
                frame,
                context.read(),
              ),
            );
            break;

          case GameFrameNightRoleAction frame:
            frameWidget = GameScreenNightRoleActionWidget(
              viewModel: GameNightRoleActionViewModel(widget.viewModel, frame),
            );
            break;

          default:
            frameWidget = Text(
              "No widget for: ${widget.viewModel.current.runtimeType.toString()}",
            );
            break;
        }

        final state = widget.viewModel.state;
        final appBarColors = widget.viewModel.getAppBarColors();

        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: appBarColors.$1,
            foregroundColor: appBarColors.$2,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: appBarColors.$3,
                ),
              ),
            ),
            title: Text(widget.viewModel.getInstructionTitle()),
            actions: [
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => widget.viewModel.moveBottom(),
                    leadingIcon: Icon(Icons.first_page),
                    child: Text("Move to beginning"),
                  ),

                  MenuItemButton(
                    onPressed: () {
                      var scores = context
                          .read<GameRepository>()
                          .calculateScores(widget.viewModel.current);

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.9,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GameScoresWidget(scores: scores),
                          ),
                        ),
                      );
                    },

                    leadingIcon: Icon(Icons.score),
                    child: Text("Calculate scores"),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ExportToSheetsWidget(
                              frame: widget.viewModel.current,
                              repository: context.read<GameRepository>(),
                            ),
                          ),
                        ),
                      );
                    },
                    leadingIcon: Icon(Icons.table_chart),
                    child: Text("Export to Sheets"),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.6,
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: BackupTimerWidget(
                                viewModel: BackupTimerViewModel(context.read()),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    leadingIcon: Icon(Icons.timer),
                    child: Text("Backup timer"),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.75,
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: MusicPlayerWidget(
                                viewModel: MusicPlayerViewModel(
                                  musicService: context.read(),
                                  showPlaylist: true,
                                  playlist:
                                      widget.viewModel.playlistForCurrentState,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    leadingIcon: Icon(Icons.play_circle),
                    child: Text("Music player"),
                  ),
                  MenuItemButton(
                    onPressed: () async {
                      var repo = context.read<GameRepository>();
                      var messenger = ScaffoldMessenger.of(context);

                      var result = await repo.duplicate(
                        widget.viewModel.current,
                      );
                      if (result.isValue) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.asValue!.value),
                            action: SnackBarAction(
                              label: "Undo",
                              onPressed: () =>
                                  repo.undoDuplication(result.asValue!.value),
                            ),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Failed to duplicate!")),
                        );
                      }
                    },
                    leadingIcon: Icon(Icons.fork_right),
                    child: Text("Duplicate game save"),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        GameUILib.confirmDialogWithDuplicationOption(
                          context,
                          widget.viewModel.current,
                          () {
                            widget.viewModel.override();
                          },
                        ),

                    leadingIcon: Icon(Icons.restore_page),
                    child: Text("Narrator override"),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        GameUILib.confirmDialogWithDuplicationOption(
                          context,
                          widget.viewModel.current,
                          () {
                            widget.viewModel.penalize();
                          },
                        ),
                    leadingIcon: Icon(Icons.local_police),
                    child: Text("Penalize player"),
                  ),
                ],
                builder: (context, controller, child) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: true,
            bottom: false,
            left: true,
            right: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Expanded(child: Center(child: frameWidget)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadiusGeometry.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: BoxBorder.all(color: Colors.grey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: true,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          left: 8,
                          right: 8,
                        ),
                        child: Column(
                          spacing: 8,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) =>
                                          GameOverviewPopupWidget(
                                            viewModel: GameOverviewViewModel(
                                              frame: widget.viewModel.current,
                                              state: widget.viewModel.state,
                                              voteOn: widget.viewModel.voteOn,
                                            ),
                                          ),
                                    ),
                                    child: widget.viewModel.hideTeamCounters
                                        ? GamePlayerTotalCountWidget(
                                            state: widget.viewModel.state,
                                          )
                                        : GamePlayerCountersWidget(
                                            state: widget.viewModel.state,
                                          ),
                                  ),
                                ),

                                if (state.gameResult != GameResult.none)
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: GameResultWidget(
                                      result: state.gameResult,
                                    ),
                                  ),

                                if (state.gameResult == GameResult.none)
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: GameDayWidget(day: state.dayCount),
                                  ),

                                Visibility(
                                  visible: widget.viewModel.voteOn.isNotEmpty,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius:
                                            BorderRadiusGeometry.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(widget.viewModel.voteOn),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton(
                                    onPressed: widget.viewModel.canMoveTop()
                                        ? () =>
                                              GameUILib.confirmDialogWithDuplicationOption(
                                                context,
                                                widget.viewModel.current,
                                                () => widget.viewModel.setTop(),
                                              )
                                        : null,
                                    child: Icon(Icons.vertical_align_top),
                                  ),
                                ),

                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      FilledButton(
                                        onPressed: () =>
                                            widget.viewModel.moveBackward(),
                                        child: Icon(Icons.keyboard_arrow_left),
                                      ),
                                      Text(
                                        "${widget.viewModel.currentIndex}/${widget.viewModel.frameCount}",
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            widget.viewModel.moveForward(),
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                widget.viewModel
                                                        .willMovingCommit()
                                                    ? Colors.green
                                                    : null,
                                              ),
                                        ),
                                        child: Icon(
                                          widget.viewModel.willMovingCommit()
                                              ? Icons.download_done
                                              : Icons.keyboard_arrow_right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: widget.viewModel.canMoveTop()
                                        ? () => widget.viewModel.moveTop()
                                        : null,
                                    child: Icon(Icons.last_page),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ExportToSheetsWidget extends StatefulWidget {
  const ExportToSheetsWidget({
    super.key,
    required this.frame,
    required this.repository,
  });
  final GameFrame frame;
  final GameRepository repository;

  @override
  State<ExportToSheetsWidget> createState() => _ExportToSheetsWidgetState();
}

class _ExportToSheetsWidgetState extends State<ExportToSheetsWidget> {
  late final String _dayActionsText;
  late final String _nightActionsText;
  late final String _firstNightGuessesText;

  @override
  void initState() {
    super.initState();
    _dayActionsText = widget.repository
        .exportDayActionsToSheet(widget.frame)
        .map((row) => row.join('\t'))
        .join('\n');
    _nightActionsText = widget.repository
        .exportNightActionsToSheets(widget.frame)
        .map((row) => row.join('\t'))
        .join('\n');
    _firstNightGuessesText = widget.repository
        .exportFirstNightGuessesToSheet(widget.frame)
        .map((row) => row.join('\t'))
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: _dayActionsText)),
          icon: Icon(Icons.copy),
          label: Text('Copy day actions'),
        ),
        const SizedBox(height: 4),
        Text(
          'Put the cursor on the first player name and paste',
          style: labelStyle,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: _nightActionsText)),
          icon: Icon(Icons.copy),
          label: Text('Copy night actions'),
        ),
        const SizedBox(height: 4),
        Text(
          'Put the cursor on the first Priest action and paste',
          style: labelStyle,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: _firstNightGuessesText)),
          icon: Icon(Icons.copy),
          label: Text('Copy first night guesses'),
        ),
        const SizedBox(height: 4),
        Text(
          'Put the cursor on first guess field and paste',
          style: labelStyle,
        ),
      ],
    );
  }
}

abstract class GameLogEntry {}

class GameLogDayVoteEntry extends GameLogEntry {
  final int day;
  final List<GamePlayer> players;
  GameLogDayVoteEntry(this.day, this.players);
}

class GameLogNightActionEntry extends GameLogEntry {
  final int night;
  final GameRole role;
  final GamePlayer? actor;
  final GamePlayer? target;
  final String verb;
  final bool saved;
  GameLogNightActionEntry({
    required this.night,
    required this.role,
    required this.actor,
    required this.target,
    required this.verb,
    this.saved = false,
  });
}

class GameOverviewViewModel {
  final List<GamePlayer> players;
  final List<GameLogEntry> log;
  final GameState state;
  final String voteOn;

  GameOverviewViewModel({
    required GameFrame frame,
    required this.state,
    required this.voteOn,
  }) : players = state.players,
       log = _buildLog(frame, state.players);

  static String? _verbForRole(GameRole role) => switch (role) {
    GameRole.priest => 'blocked',
    GameRole.don => 'checked',
    GameRole.sheriff => 'checked',
    GameRole.mafia => 'killed',
    GameRole.killer => 'killed',
    GameRole.doctor => 'healed',
    _ => null,
  };

  static List<GameLogEntry> _buildLog(
    GameFrame frame,
    List<GamePlayer> players,
  ) {
    final List<GameLogEntry> log = [];
    int dayCount = 0;
    int nightCount = 0;
    final List<GameFrameNightRoleAction> nightBuffer = [];

    void flushNight() {
      if (nightBuffer.isEmpty) return;
      final doctorIndex = nightBuffer
          .where((f) => f.role == GameRole.doctor)
          .firstOrNull
          ?.index;
      for (final f in nightBuffer) {
        final verb = _verbForRole(f.role);
        if (verb == null) continue;
        final actor = players.where((p) => p.role == f.role).firstOrNull;
        final target =
            players.where((p) => p.index == f.index).firstOrNull ??
            GamePlayer(f.index!, '?');
        final isKill = f.role == GameRole.mafia || f.role == GameRole.killer;
        final saved = isKill && doctorIndex != null && doctorIndex == f.index;
        log.add(
          GameLogNightActionEntry(
            night: nightCount,
            role: f.role,
            actor: actor,
            target: target,
            verb: verb,
            saved: saved,
          ),
        );
      }
      nightBuffer.clear();
    }

    GameFrame? current = frame.findFirst();
    while (current != null) {
      switch (current) {
        case GameFrameNightStart _:
          nightCount++;
        case GameFrameDayStart _:
          flushNight();
          dayCount++;
        case GameFrameDayPlayersVotedOut f:
          final votedPlayers = f.playersVotedOut
              .map(
                (i) =>
                    players.where((p) => p.index == i).firstOrNull ??
                    GamePlayer(i, '?'),
              )
              .toList();
          log.add(GameLogDayVoteEntry(dayCount, votedPlayers));
        case GameFrameNightRoleAction f:
          if (f.index != null) nightBuffer.add(f);
        default:
          break;
      }
      if (current == frame) break;
      current = current.next;
    }
    flushNight();

    return log;
  }
}

class GameOverviewPopupWidget extends StatefulWidget {
  const GameOverviewPopupWidget({super.key, required this.viewModel});
  final GameOverviewViewModel viewModel;

  @override
  State<GameOverviewPopupWidget> createState() =>
      _GameOverviewPopupWidgetState();
}

class _GameOverviewPopupWidgetState extends State<GameOverviewPopupWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: _expanded ? 0.9 : 0.7,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    GameDayWidget(day: widget.viewModel.state.dayCount),
                    GameResultWidget(result: widget.viewModel.state.gameResult),
                  ],
                ),
              ),
              GamePlayerCountersWidget(state: widget.viewModel.state),
              if (widget.viewModel.voteOn.isNotEmpty)
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadiusGeometry.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.viewModel.voteOn),
                    ),
                  ),
                ),
              GamePlayerSelectorWidget(
                players: widget.viewModel.players.map(
                  (p) => GamePlayerSelectorViewModel(p),
                ),
                showRoles: true,
                onPress: null,
                shrinkWrap: true,
              ),
              if (widget.viewModel.log.isNotEmpty) ...[
                const Divider(),
                Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildLogEntries(widget.viewModel.log),
                ),
              ],
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.close_fullscreen : Icons.open_in_full,
                  ),
                  label: Text(_expanded ? 'Collapse' : 'Expand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLogEntries(List<GameLogEntry> entries) =>
      entries.map(_buildLogEntry).toList();

  static const _dayBg = Color(0xffffffdd);
  static const _nightBg = Color(0xFF444444);
  static const _nightFg = Colors.white;

  Widget _buildLogEntry(GameLogEntry entry) {
    switch (entry) {
      case GameLogDayVoteEntry e:
        return _logRow(
          color: _dayBg,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Day ${e.day}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...e.players.map(
                (p) => GamePlayerBadgeWidget(
                  player: p,
                  showRole: true,
                  fontSize: 14,
                ),
              ),
              const Text('voted out'),
            ],
          ),
        );
      case GameLogNightActionEntry e:
        final isKill = e.verb == 'killed';
        return _logRow(
          color: _nightBg,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Night ${e.night}:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _nightFg,
                ),
              ),
              if (e.role == GameRole.mafia)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: GameUILib.roleViewModel(GameRole.mafia).background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Mafia',
                      style: TextStyle(
                        fontSize: 14,
                        color: GameUILib.roleViewModel(GameRole.mafia).foreground,
                      ),
                    ),
                  ),
                )
              else if (e.actor != null)
                GamePlayerBadgeWidget(
                  player: e.actor!,
                  showRole: true,
                  fontSize: 14,
                ),
              Text(
                e.verb,
                style: TextStyle(
                  color: _nightFg,
                  fontWeight: isKill ? FontWeight.bold : FontWeight.normal,
                  decoration: e.saved ? TextDecoration.lineThrough : null,
                  decorationColor: _nightFg,
                ),
              ),
              if (e.target != null)
                GamePlayerBadgeWidget(
                  player: e.target!,
                  showRole: true,
                  fontSize: 14,
                ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _logRow({required Color color, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: child,
      ),
    );
  }
}
