import 'dart:io';

import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/music_service.dart';

Future<Map<MusicPlaylist, List<MusicTrack>>> loadPlaylists(FileSystemService fileSystemService) async {
  final result = <MusicPlaylist, List<MusicTrack>>{};
    final dir = await fileSystemService.openMusicDirectory();
    if (!await dir.exists()) return result;

    final operatorExp = RegExp(r"[\.]?(\$([a-z]+)(\d+))[\.]?");
    final extensionExp = RegExp(r"(\.mp3|ogg|wav|mp4)$");

    final nameMap = MusicPlaylist.values.asNameMap();
    await for (final folderEntity in dir.list()) {
      if (folderEntity is Directory) {
        final playlistName = folderEntity
            .uri
            .pathSegments[folderEntity.uri.pathSegments.length - 2];

        final playlist = nameMap[playlistName];
        if (playlist == null) {
          continue;
        }

        if (!result.containsKey(playlist)) result[playlist] = [];
        await for (final fileEntity in folderEntity.list()) {
          if (fileEntity is! File) continue;
          final fileName = fileEntity.uri.pathSegments.last;
          final extensionMatch = extensionExp.firstMatch(fileName);
          if (extensionMatch == null) continue;

          var title = fileName.replaceFirst(extensionMatch.group(0)!, "");
          double? volumeAdjustment;
          Duration? leadingSkip;
          Duration? trailingSkip;

          for (final match in operatorExp.allMatches(fileName)) {
            final argument = int.tryParse(match.group(3) ?? "");
            if (argument == null) continue;

            title = title.replaceFirst(".${match.group(1)!}", "");
            title = title.replaceFirst(".${match.group(1)!}.", "");
            title = title.replaceFirst(match.group(1)!, "");
            switch (match.group(2)) {
              case "l":
                leadingSkip = Duration(seconds: argument);
                break;
              case "t":
                trailingSkip = Duration(seconds: argument);
                break;
              case "v":
                volumeAdjustment = argument / 100;
                break;
              default:
                break;
            }
          }

          result[playlist]!.add(
            MusicTrack(
              path: fileEntity.path,
              title: title,
              playlist: nameMap[playlistName]!,
              skipLeading: leadingSkip,
              skipTrailing: trailingSkip,
              volumeAdjustment: volumeAdjustment,
            ),
          );
        }
      }
    }
  return result;
}
