import 'package:flutter/material.dart';
import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';

class SettingsViewModel extends ChangeNotifier {
  final GameConfigService configService;
  final FileSystemService fileSystemService;
  String documentsPath = "...";

  SettingsViewModel({
    required this.configService,
    required this.fileSystemService,
  }) {
    fileSystemService.getStoragePath().then((path) {
      documentsPath = path;
      notifyListeners();
    });
  }

  void reset() {
    configService.reset();
    notifyListeners();
  }

  void save() {
    configService.save();
    notifyListeners();
  }
}

class SettingsScreen extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    void add(String title, Function(String value) setter, String initialValue) {
      widgets.add(
        Row(
          spacing: 16,
          children: [
            Expanded(child: Text(title)),
            SizedBox(
              width: 80,
              child: TextField(
                controller: TextEditingController.fromValue(
                  TextEditingValue(text: initialValue),
                ),
                onChanged: (value) => setter(value),
              ),
            ),
          ],
        ),
      );
    }

    Function(String stringValue) toIntSetter(Function(int value) callback) {
      return (stringValue) {
        final value = int.tryParse(stringValue);
        if (value != null) {
          callback(value);
        }
      };
    }

    Function(String stringValue) percentageAsFractionSetter(
      Function(double value) callback,
    ) {
      return (stringValue) {
        final value = int.tryParse(stringValue);
        if (value != null) {
          callback(value / 100);
        }
      };
    }

    add(
      "Max amount of games",
      toIntSetter((v) => viewModel.configService.maxAmountOfGames = v),
      viewModel.configService.maxAmountOfGames.toString(),
    );

    add(
      "Amount of tables",
      toIntSetter((v) => viewModel.configService.amountOfTables = v),
      viewModel.configService.amountOfTables.toString(),
    );

    widgets.add(Divider());

    add(
      "Zero night meet time (seconds)",
      toIntSetter((v) => viewModel.configService.zeroNightMeetTimer = v),
      viewModel.configService.zeroNightMeetTimer.toString(),
    );

    add(
      "Speech time (seconds)",
      toIntSetter((v) => viewModel.configService.speechTimer = v),
      viewModel.configService.speechTimer.toString(),
    );

    add(
      "Night action time (seconds)",
      toIntSetter((v) => viewModel.configService.nightActionTimer = v),
      viewModel.configService.nightActionTimer.toString(),
    );


    add(
      "Farewell speech time (seconds)",
      toIntSetter((v) => viewModel.configService.farewellTimer = v),
      viewModel.configService.farewellTimer.toString(),
    );

    add(
      "Voting defense time (seconds)",
      toIntSetter((v) => viewModel.configService.voteDefenseTimer = v),
      viewModel.configService.voteDefenseTimer.toString(),
    );

    widgets.add(Divider());
    add(
      "Music volume (0-100)",
      percentageAsFractionSetter(
        (v) => viewModel.configService.musicVolume = v,
      ),
      (viewModel.configService.musicVolume * 100).toInt().toString(),
    );

    add(
      "Music fade-in (seconds)",
      toIntSetter(
        (v) => viewModel.configService.musicFadeInDurationSeconds = v,
      ),
      viewModel.configService.musicFadeInDurationSeconds.toString(),
    );

    add(
      "Music fade-out (seconds)",
      toIntSetter(
        (v) => viewModel.configService.musicFadeOutDurationSeconds = v,
      ),
      viewModel.configService.musicFadeOutDurationSeconds.toString(),
    );

    add(
      "Music crossfade (seconds)",
      toIntSetter(
        (v) => viewModel.configService.musicCrossfadeDurationSeconds = v,
      ),
      viewModel.configService.musicCrossfadeDurationSeconds.toString(),
    );

    widgets.add(Divider());
    widgets.add(Text("Storage path:"));
    widgets.add(
      ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) =>
            Text(viewModel.documentsPath, style: TextStyle(color: Colors.grey)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        shadowColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm reset settings:"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(Colors.black),
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.redAccent,
                        ),
                      ),
                      onPressed: () {
                        viewModel.reset();
                        Navigator.pop(context);
                      },
                      child: Text("Confirm"),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) => FloatingActionButton.extended(
          label: Text("Save"),
          icon: Icon(Icons.save),
          onPressed: () {
            viewModel.save();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(children: widgets),
            ),
          ),
        ),
      ),
    );
  }
}
