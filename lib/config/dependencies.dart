import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  return [
    Provider.value(value: GameRepository()),
    Provider.value(value: GameTimer()),
    Provider.value(value: GameConfigService()),
  ];
}
