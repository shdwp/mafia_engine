import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    _repository.iterateSavedGames().then((value) {
      savedGames = value.asValue!.value.toList();
      notifyListeners();
    });
  }
  final GameRepository _repository;

  List<String> savedGames = List.empty();
}
