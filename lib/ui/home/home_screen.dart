import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/routing/routes.dart';
import 'package:provider/provider.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    _repository.iterateSavedGames().then((value) {
      savedGames = value.asValue!.value.toList();
      notifyListeners();
    });
  }
  final GameRepository _repository;

  List<GameSaveFile> savedGames = List.empty();
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
      appBar: AppBar(title: Text("Mafia Engine")),
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
          padding: const EdgeInsets.all(16.0),
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
                              Expanded(child: Text(game.name)),
                              Text(
                                style: TextStyle(color: Colors.grey),
                                formatter.format(game.modifiedDate),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await context
                                        .read<GameRepository>()
                                        .loadGame(game.path);

                                    if (result.isError) {
                                      print(result.asError!);
                                      return;
                                    } else if (result.isValue) {
                                      context.go(
                                        Routes.game,
                                        extra: result.asValue!.value,
                                      );
                                    }
                                  },
                                  child: Text("Load"),
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
