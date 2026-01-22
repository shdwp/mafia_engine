import 'package:go_router/go_router.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/routing/routes.dart';
import 'package:mafia_engine/ui/home/home_screen.dart';
import 'package:mafia_engine/ui/home/home_viewmodel.dart';
import 'package:provider/provider.dart';

import '../ui/game/game_screen.dart';
import '../ui/game/game_viewmodel.dart';

GoRouter router() => GoRouter(
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewModel(context.read());
        return HomeScreen(viewModel: viewModel);
      },
      routes: [
        GoRoute(
          path: Routes.game,
          builder: (context, state) {
            final gameState = state.extra as GameState;
            return GameScreen(
              viewModel: GameViewModel(
                repository: context.read(),
                state: gameState,
              ),
            );
          },
        ),
      ],
    ),
  ],
);
