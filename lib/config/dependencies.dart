import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_controller.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_timer.dart';
import 'package:mafia_engine/data/music_service.dart';
import 'package:mafia_engine/data/storage_native.dart' if (dart.library.html) 'package:mafia_engine/data/storage_web.dart' as storage_factory;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  final fileSystemService = FileSystemService();
  final storage = storage_factory.createStorage(fileSystemService);
  final configService = GameConfigService(storage: storage);
  final repository = GameRepository(storage, configService);
  final musicService = MusicService(configService, fileSystemService);

  return [
    Provider.value(value: fileSystemService),
    Provider.value(value: storage),
    Provider.value(value: repository),
    Provider.value(value: GameTimer(configService)),
    Provider.value(value: configService),
    Provider.value(value: musicService),
    Provider.value(
      value: GameController(
        repository: repository,
        musicService: musicService,
        configService: configService,
      ),
    ),
  ];
}
