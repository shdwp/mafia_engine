import 'dart:io';

import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/storage.dart';

AppStorage createStorage(FileSystemService fileSystem) => NativeStorage(fileSystem);

class NativeStorage implements AppStorage {
  final FileSystemService fileSystem;

  NativeStorage(this.fileSystem);

  Future<File> _file(String group, String name) async {
    final root = await fileSystem.getStoragePath();
    final directory = group == 'root' ? root : '$root/$group';
    return File('$directory/$name');
  }

  @override
  Future<StoredText?> read(String group, String name) async {
    final file = await _file(group, name);
    if (!await file.exists()) return null;
    return StoredText(name, await file.readAsString(), await file.lastModified());
  }

  @override
  Future<void> write(String group, String name, String content) async {
    final file = await _file(group, name);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<List<StoredText>> list(String group) async {
    final root = await fileSystem.getStoragePath();
    final directory = Directory(group == 'root' ? root : '$root/$group');
    if (!await directory.exists()) return [];
    final result = <StoredText>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        result.add(StoredText(
          entity.uri.pathSegments.last,
          await entity.readAsString(),
          await entity.lastModified(),
        ));
      }
    }
    return result;
  }

  @override
  Future<void> delete(String group, String name) async {
    final file = await _file(group, name);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> move(String from, String to, String name) async {
    final source = await _file(from, name);
    final target = await _file(to, name);
    await target.create(recursive: true);
    await source.copy(target.path);
    await source.delete();
  }
}
