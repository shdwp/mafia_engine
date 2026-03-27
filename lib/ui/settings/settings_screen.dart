import 'package:flutter/material.dart';
import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/game_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsViewModel extends ChangeNotifier {
  final GameConfigService configService;
  final FileSystemService fileSystemService;
  String documentsPath = "...";
  String appVersion = "...";

  SettingsViewModel({
    required this.configService,
    required this.fileSystemService,
  }) {
    fileSystemService.getStoragePath().then((path) {
      documentsPath = path;
      notifyListeners();
    });
    PackageInfo.fromPlatform().then((info) {
      appVersion = info.version;
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

    widgets.add(
      Row(
        spacing: 16,
        children: [
          Expanded(child: Text("Hide sensitive information on day screen")),
          StatefulBuilder(
            builder: (context, setState) => Checkbox(
              value: viewModel.configService.hideSensitiveInfoOnDayScreen,
              onChanged: (value) {
                viewModel.configService.hideSensitiveInfoOnDayScreen =
                    value ?? false;
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );

    widgets.add(
      Row(
        spacing: 16,
        children: [
          Expanded(child: Text("Defensive speeches always available")),
          StatefulBuilder(
            builder: (context, setState) => Checkbox(
              value: viewModel.configService.defensiveSpeechesAlwaysAvailable,
              onChanged: (value) {
                viewModel.configService.defensiveSpeechesAlwaysAvailable =
                    value ?? true;
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );

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
      "Timer sound volume (0-100)",
      percentageAsFractionSetter(
        (v) => viewModel.configService.timerSoundVolume = v,
      ),
      (viewModel.configService.timerSoundVolume * 100).toInt().toString(),
    );
    widgets.add(Text("Set to 0 if you don't want the timer sounds.", style: TextStyle(color: Colors.grey)));

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

    widgets.add(
      Builder(
        builder: (context) => TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Music setup"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Folder structure",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Place music files inside the app's storage folder under music/, organised into playlist subfolders:",
                    ),
                    SizedBox(height: 4),
                    Text(
                      "music/preparation/\n"
                      "music/lowIntensity/\n"
                      "music/mediumIntensity/\n"
                      "music/highIntensity/\n"
                      "music/special/",
                      style: TextStyle(fontFamily: "monospace"),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Supported formats",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(".mp3, .ogg, .wav, .mp4"),
                    SizedBox(height: 12),
                    Text(
                      "When each playlist plays",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "special       — can be manually selected\n"
                      "preparation   — day 0 (zero night)\n"
                      "lowIntensity  — day 1\n"
                      "mediumIntensity — days 2–3\n"
                      "highIntensity — day 4 and beyond",
                      style: TextStyle(fontFamily: "monospace"),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Empty playlists",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "If a playlist folder is missing or empty, the app cycles forward through the playlist order (preparation → lowIntensity → mediumIntensity → highIntensity → special → preparation → …) until it finds a non-empty one. If all playlists are empty, no music plays.",
                    ),
                    SizedBox(height: 12),
                    Text(
                      "File naming operators",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Add operators anywhere in the filename (before the extension) to control playback:\n\n"
                      "  \$v{N}  — volume, where N is 0–100\n"
                      "           e.g. track.\$v80.mp3 → 80% volume\n\n"
                      "  \$l{N}  — skip N seconds from the start\n"
                      "           e.g. track.\$l5.mp3 → skip first 5 s\n\n"
                      "  \$t{N}  — trim N seconds from the end\n"
                      "           e.g. track.\$t3.mp3 → stop 3 s early\n\n"
                      "Operators can be combined:\n"
                      "  track.\$v90.\$l2.\$t4.mp3",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            ),
          ),
          icon: Icon(Icons.help_outline),
          label: Text("How to set up music"),
        ),
      ),
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

    widgets.add(Text("Version:"));
    widgets.add(
      ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) => Text(
          "${viewModel.appVersion}/${viewModel.configService.configVersion}",
          style: TextStyle(color: Colors.grey),
        ),
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
