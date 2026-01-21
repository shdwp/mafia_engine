import 'package:flutter/material.dart';
import 'package:mafia_engine/config/dependencies.dart';
import 'package:mafia_engine/routing/router.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: providers, child: const MafEngineApp()));
}

class MafEngineApp extends StatelessWidget {
  const MafEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router());
  }
}
