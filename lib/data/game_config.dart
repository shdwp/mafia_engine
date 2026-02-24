class GameConfigService {
  int get amountOfTables => 2;
  int get maxAmountOfGames => 3;

  int get speechTimer => 60;
  int get farewellTimer => 30;
  int get voteDefenseTimer => 30;

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
}
