import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileSystemService {
  Future<String> getStoragePath() async {
    var directory = Directory("");
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      directory = Directory("/storage/emulated/0/Documents/MafiaEngine");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final exPath = directory.path;
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  Future<File> openPlayerNamesFile() async {
    final directory = await getStoragePath();
    final path = "$directory/names/names.json";
    final file = File(path);

    await file.create(recursive: true);
    return file;
  }

  Future<File> openSaveGameFile(String fileName) async {
    final directory = await getStoragePath();
    final path = "$directory/games/$fileName";
    return File(path);
  }

  Future<File> openSettingsFile() async {
    final directory = await getStoragePath();
    final path = "$directory/settings.json";
    return File(path);
  }

  Future moveToBackupFolder(String fileName) async {
    final directory = await getStoragePath();
    final path = "$directory/games/$fileName";
    final file = File(path);
    await Directory("$directory/gamesBackup/").create(recursive: true);
    await file.copy("$directory/gamesBackup/$fileName");
    await file.delete();
  }

  Future moveFromBackupFolder(String fileName) async {
    final directory = await getStoragePath();
    final path = "$directory/gamesBackup/$fileName";
    final file = File(path);
    Directory("$directory/games/").create(recursive: true);
    await file.copy("$directory/games/$fileName");
    await file.delete();
  }

  Future<Directory> openSaveGameDirectory(String type) async {
    final directory = await getStoragePath();
    final dir = Directory("$directory/$type/");
    return dir;
  }

  Future<Directory> openMusicDirectory() async {
    final directory = await getStoragePath();
    final dir = Directory("$directory/music/");
    return dir;
  }
}
