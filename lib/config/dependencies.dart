import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:mafia_engine/data/music_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  final fileSystemService = FileSystemService();
  final configService = GameConfigService(fileSystemService: fileSystemService);
  final repository = GameRepository(fileSystemService, configService);
  final musicService = MusicService(configService, fileSystemService);

  return [
    Provider.value(value: fileSystemService),
    Provider.value(value: repository),
    Provider.value(value: GameTimer()),
    Provider.value(value: configService),
    Provider.value(value: musicService),
    Provider.value(
      value: GameController(repository: repository, musicService: musicService),
    ),
  ];
}
