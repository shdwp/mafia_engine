import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/routing/routes.dart';
import 'package:mafia_engine/ui/home/home_viewmodel.dart';
import 'package:provider/provider.dart';

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
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            Center(child: Text("Mafia Engine")),
            SizedBox(height: 10),
            SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                context.go(
                  Routes.game,
                  extra: context.read<GameRepository>().newGame(),
                );
              },
              child: Text("Start game"),
            ),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) => Expanded(
                child: ListView.builder(
                  itemCount: widget.viewModel.savedGames.length,
                  itemBuilder: (context, index) {
                    final segment = widget.viewModel.savedGames[index];
                    return FilledButton(
                      onPressed: () async {
                        final result = await context
                            .read<GameRepository>()
                            .loadGame(segment);

                        if (result.isError) {
                          print(result.asError!);
                          return;
                        } else if (result.isValue) {
                          context.go(Routes.game, extra: result.asValue!.value);
                        }
                      },
                      child: Text(segment),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
