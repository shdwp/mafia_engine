import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/music_service.dart';
import 'package:mafia_engine/routing/routes.dart';
import 'package:mafia_engine/ui/game/narrator/game_narrator_widgets.dart';
import 'package:provider/provider.dart';

class HomeViewModel extends ChangeNotifier {
  final GameRepository _repository;
  final MusicService _musicService;

  HomeViewModel(this._repository, this._musicService) {
    reloadSavedGames();
  }

  List<GameSaveFile> savedGames = List.empty();
  MusicPlaylist get musicPlaylist =>
      _musicService.findNonEmptyPlaylist(MusicPlaylist.special);

  void reloadSavedGames() {
    _repository.iterateSavedGames().then((value) {
      savedGames = value.asValue!.value.toList();
      notifyListeners();
    });
  }

  void undoLastDeletion() async {
    await _repository.undoLastDeletion();
    reloadSavedGames();
  }

  void delete(GameSaveFile file) async {
    await _repository.delete(file.fileName);
    reloadSavedGames();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mafia Engine"),
        shadowColor: Colors.black,
        actions: [
          MenuAnchor(
            menuChildren: [
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
                              playlist: widget.viewModel.musicPlaylist,
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
                onPressed: () => widget.viewModel.undoLastDeletion(),
                leadingIcon: Icon(Icons.undo),
                child: Text("Undo last deletion"),
              ),
              MenuItemButton(
                onPressed: () => context.go(Routes.settings),
                leadingIcon: Icon(Icons.settings),
                child: Text("Settings"),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("New game"),
        icon: Icon(Icons.add),
        onPressed: () => context.go(
          Routes.game,
          extra: context.read<GameRepository>().newGame(),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, child) => Expanded(
                  child: ListView.separated(
                    padding: EdgeInsetsGeometry.only(bottom: 64),
                    itemCount: widget.viewModel.savedGames.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final game = widget.viewModel.savedGames[index];
                      final DateFormat formatter = DateFormat("HH:mm:ss");
                      return Column(
                        children: [
                          Row(
                            spacing: 4,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final result = await context
                                        .read<GameRepository>()
                                        .loadGame(game);

                                    if (result.isError) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Failed to load game!"),
                                          content: Text(
                                            result.asError!.error.toString(),
                                          ),
                                        ),
                                      );
                                      return;
                                    } else if (result.isValue) {
                                      context.go(
                                        Routes.game,
                                        extra: result.asValue!.value,
                                      );
                                    }
                                  },
                                  style: ButtonStyle(
                                    alignment: AlignmentGeometry.centerLeft,
                                  ),
                                  child: Text(game.name),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: game.frameCount > 0
                                      ? (game.frameCount > 10
                                            ? Colors.green
                                            : Colors.grey)
                                      : Colors.red,
                                  child: Text(
                                    game.frameCount.toString(),
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),

                              Text(
                                style: TextStyle(color: Colors.grey),
                                formatter.format(game.modifiedDate),
                              ),

                              MenuAnchor(
                                menuChildren: [
                                  MenuItemButton(
                                    onPressed: () =>
                                        widget.viewModel.delete(game),
                                    leadingIcon: Icon(Icons.delete),
                                    child: Text("Delete"),
                                  ),
                                ],
                                builder: (context, controller, child) =>
                                    IconButton(
                                      icon: Icon(Icons.more_vert),
                                      onPressed: () => controller.isOpen
                                          ? controller.close()
                                          : controller.open(),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
