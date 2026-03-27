import 'package:async/async.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:mafia_engine/data/game_frame.dart';
import 'package:mafia_engine/data/game_frame_tree.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/data/game_state.dart';
import 'package:mafia_engine/data/music_service.dart';

class GameController {
  final GameRepository _repository;
  final MusicService _musicService;
  final GameConfigService _configService;

  GameController({
    required GameRepository repository,
    required MusicService musicService,
    required GameConfigService configService,
  }) : _repository = repository,
       _musicService = musicService,
       _configService = configService;

  Result<GameState> moveBackward(GameFrame currentFrame) {
    return currentFrame.previous != null
        ? Result.value(GameState.calculate(currentFrame.previous!))
        : Result.error(GameError.noPrevious);
  }

  Result<GameState> moveForward(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    if (currentFrame.next != null) {
      return Result.value(GameState.calculate(currentFrame.next!));
    }

    return Result.error(GameError.noNext);
  }

  Result<GameState> moveTop(GameFrame currentFrame) {
    if (currentFrame.isDirty) {
      return Result.error(GameError.frameDirty);
    }

    final lastFrame = currentFrame.findLast();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> moveBottom(GameFrame currentFrame) {
    final lastFrame = currentFrame.findFirst();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> setTop(GameFrame currentFrame) {
    currentFrame.next = null;
    final lastFrame = currentFrame.findLast();
    return Result.value(GameState.calculate(lastFrame));
  }

  Result<GameState> commitFrame(GameFrame frame) {
    if (!frame.isDirty) return Result.error(GameError.frameNotDirty);
    if (!frame.isValid) return Result.error(GameError.frameInvalid);

    if (frame is GameFrameAddPlayers) {
      _repository.commitPlayerNames(frame.players);
    }

    var state = GameState.calculate(frame, ignoreLast: false);
    frame.previous?.next = frame;
    frame.dirty = false;
    frame.next = GameState.createNextFrame(
      frame,
      state,
      defensiveSpeechesAlwaysAvailable:
          _configService.defensiveSpeechesAlwaysAvailable,
    );
    frame.next!.previous = frame;

    _repository.saveTree(frame);
    return Result.value(GameState.calculate(frame.next!));
  }

  bool willCommitOverwriteHistory(GameFrame frame) {
    return frame.next != null;
  }

  bool shouldFrameBeCommited(GameFrame frame) {
    return frame.isDirty;
  }

  Result<GameState> penalize(GameFrame frame) {
    var newFrame = GameFrameNarratorPenalize();
    frame.previous!.next = newFrame;
    newFrame.next = frame;
    newFrame.previous = frame.previous!;
    frame.previous = newFrame;

    var state = GameState.calculate(newFrame);
    _repository.saveTree(newFrame);
    return Result.value(state);
  }

  Result<GameState> override(GameFrame frame) {
    var state = GameState.calculate(frame);
    var newFrame = GameFrameNarratorStateOverride(
      GameFrameNarratorStateOverrideType.dayStart,
      state.players.map((p) {
        return (p.name, p.role, p.alive, p.penalties);
      }).toList(),
    );
    frame.previous!.next = newFrame;
    newFrame.previous = frame.previous!;
    frame.previous = newFrame;

    var newState = GameState.calculate(newFrame);
    _repository.saveTree(newFrame);
    return Result.value(newState);
  }

  MusicPlaylist playlistForFrame(GameFrame currentFrame) {
    var state = GameState.calculate(currentFrame);

    var playlist = MusicPlaylist.preparation;
    switch (state.dayCount) {
      case 0:
        playlist = MusicPlaylist.preparation;
        break;
      case 1:
        playlist = MusicPlaylist.lowIntensity;
        break;
      case 2:
      case 3:
        playlist = MusicPlaylist.mediumIntensity;
        break;
      default:
        playlist = MusicPlaylist.highIntensity;
        break;
    }

    return _musicService.findNonEmptyPlaylist(playlist);
  }
}
