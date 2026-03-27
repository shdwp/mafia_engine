import 'dart:convert';
import 'dart:io';

import 'package:mafia_engine/data/filesystem.dart';
import 'package:path_provider/path_provider.dart';

class GameConfigService {
  final FileSystemService _fileSystemService;

  final int _version = 6;
  int get configVersion => _version;

  int maxAmountOfGames = 3;
  int amountOfTables = 2;
  int speechTimer = 60;
  int nightActionTimer = 20;
  int zeroNightMeetTimer = 20;
  int farewellTimer = 30;
  int voteDefenseTimer = 30;

  bool hideSensitiveInfoOnDayScreen = true;
  bool defensiveSpeechesAlwaysAvailable = true;

  double musicVolume = 0.75;
  double timerSoundVolume = 1;
  int musicCrossfadeDurationSeconds = 3;

  int musicFadeInDurationSeconds = 3;
  int musicFadeOutDurationSeconds = 3;

  Duration get musicFadeInDuration =>
      Duration(seconds: musicFadeInDurationSeconds);
  Duration get musicFadeOutDuration =>
      Duration(seconds: musicFadeOutDurationSeconds);
  Duration get musicCrossfadeDuration =>
      Duration(seconds: musicCrossfadeDurationSeconds);

  num get civilianWinPoints => 3;
  num get mafiaWinPoints => 3;
  num get killerWinPoints => 5;
  num get kmDrawMafiaPoints => mafiaWinPoints / 2;
  num get kmDrawKillerPoints => killerWinPoints / 2;

  num get sheriffFoundOpposingPlayersPoints => 1;
  num get doctorSavedCivilianPoints => 1;
  num get doctorSavedSheriffPoints => 2;

  num get priestBlockedSheriffPoints => 1;
  num get priestBlockedKilledPoints => 1;
  num get priestBlockedDoctorPoints => 1;

  num get donFoundSheriffPoints => 1;
  num get mafiaAliveWinBonusPoints => 1;
  num get killerActiveRoleKillPoints => 1;

  num get guessPointsFull => 2;
  num get guessPointsHalf => 1;

  GameConfigService({required FileSystemService fileSystemService})
    : _fileSystemService = fileSystemService {
    _startupLoadSafe();
  }

  Future reset() async {
    final file = await _fileSystemService.openSettingsFile();
    await file.delete();

    final emptyInstance = GameConfigService(
      fileSystemService: _fileSystemService,
    );
    await emptyInstance._startupLoadSafe();
    await _load();
  }

  Future save() async {
    await _save();
  }

  Future _startupLoadSafe() async {
    await _load();
    await _save();
  }

  Future _save() async {
    final file = await _fileSystemService.openSettingsFile();
    await file.create(recursive: true);

    final map = {
      "version": _version,
      "maxAmountOfGames": maxAmountOfGames,
      "amountOfTables": amountOfTables,
      "speechTimer": speechTimer,
      "farewellTimer": farewellTimer,
      "voteDefenseTimer": voteDefenseTimer,
      "nightActionTimer": nightActionTimer,
      "zeroNightMeetTimer": zeroNightMeetTimer,
      "hideSensitiveInfoOnDayScreen": hideSensitiveInfoOnDayScreen,
      "defensiveSpeechesAlwaysAvailable": defensiveSpeechesAlwaysAvailable,
      "musicVolume": musicVolume,
      "timerSoundVolume": timerSoundVolume,
      "musicCrossfadeDuration": musicCrossfadeDurationSeconds,
      "musicFadeInDurationSeconds": musicFadeInDurationSeconds,
      "musicFadeOutDurationSeconds": musicFadeOutDurationSeconds,
    };
    await file.writeAsString(json.encode(map));
  }

  Future _load() async {
    final file = await _fileSystemService.openSettingsFile();
    if (!await file.exists()) return;

    final jsonString = await file.readAsString();
    final map = json.decode(jsonString) as Map<String, dynamic>;
    if (map["version"] != _version) return;

    maxAmountOfGames = map["maxAmountOfGames"];
    amountOfTables = map["amountOfTables"];
    speechTimer = map["speechTimer"];
    farewellTimer = map["farewellTimer"];
    voteDefenseTimer = map["voteDefenseTimer"];
    nightActionTimer = map["nightActionTimer"];
    zeroNightMeetTimer = map["zeroNightMeetTimer"];
    hideSensitiveInfoOnDayScreen = map["hideSensitiveInfoOnDayScreen"] ?? false;
    defensiveSpeechesAlwaysAvailable =
        map["defensiveSpeechesAlwaysAvailable"] ?? true;
    musicVolume = map["musicVolume"];
    timerSoundVolume = map["timerSoundVolume"] ?? 0.8;
    musicCrossfadeDurationSeconds = map["musicCrossfadeDuration"];
    musicFadeInDurationSeconds = map["musicFadeInDurationSeconds"];
    musicFadeOutDurationSeconds = map["musicFadeOutDurationSeconds"];
  }
}
