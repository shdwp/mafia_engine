import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:mafia_engine/config/dependencies.dart';
import 'package:mafia_engine/routing/router.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: providers, child: const MafEngineApp()));
}

class MafEngineApp extends StatefulWidget {
  const MafEngineApp({super.key});

  @override
  State<MafEngineApp> createState() => _MafEngineAppState();
}

class _MafEngineAppState extends State<MafEngineApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<String> _saveErrors;

  @override
  void initState() {
    super.initState();
    _saveErrors = context.read<GameRepository>().saveErrors.listen((message) {
      final messenger = _messengerKey.currentState;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _saveErrors.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router(),
      scaffoldMessengerKey: _messengerKey,
    );
  }
}
