import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_enums.dart';

class GamePlayerSelectorViewModel {
  GamePlayerSelectorViewModel(this.player, this.available, this.selected);

  final GamePlayer player;
  bool available;
  bool selected;
}

class GamePlayerSelectorWidget extends StatelessWidget {
  const GamePlayerSelectorWidget({
    super.key,
    required this.players,
    required this.onPress,
  });
  final Iterable<GamePlayerSelectorViewModel> players;
  final Function(int index) onPress;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      children: List.generate(players.length, (index) {
        final element = players.elementAt(index);
        final onPressed = !element.available ? null : () => onPress(index);
        final child = Text(players.elementAt(index).player.seatName);

        if (element.selected) {
          return FilledButton(onPressed: onPressed, child: child);
        } else {
          return ElevatedButton(onPressed: onPressed, child: child);
        }
      }),
    );
  }
}
