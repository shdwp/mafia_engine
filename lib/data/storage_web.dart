import 'dart:html' as html;
import 'dart:indexed_db' as idb;

import 'package:mafia_engine/data/filesystem.dart';
import 'package:mafia_engine/data/storage.dart';

AppStorage createStorage(FileSystemService fileSystem) => WebStorage();

class WebStorage implements AppStorage {
  Future<idb.Database>? _database;

  Future<idb.Database> get database => _database ??= html.window.indexedDB!.open(
    'mafia_engine',
    version: 1,
    onUpgradeNeeded: (event) {
      final request = event.target as idb.OpenDBRequest;
      request.result!.createObjectStore('entries');
    },
  );

  String _key(String group, String name) => '$group/$name';

  @override
  Future<StoredText?> read(String group, String name) async {
    final db = await database;
    final transaction = db.transaction('entries', 'readonly');
    final value = await transaction.objectStore('entries').getObject(_key(group, name));
    if (value == null) return null;
    final entry = Map<String, dynamic>.from(value as Map);
    return StoredText(name, entry['content'] as String,
        DateTime.fromMillisecondsSinceEpoch(entry['modified'] as int));
  }

  @override
  Future<void> write(String group, String name, String content) async {
    final db = await database;
    final transaction = db.transaction('entries', 'readwrite');
    final completed = transaction.completed;
    await transaction.objectStore('entries').put({
      'content': content,
      'modified': DateTime.now().millisecondsSinceEpoch,
    }, _key(group, name));
    await completed;
  }

  @override
  Future<List<StoredText>> list(String group) async {
    final db = await database;
    final transaction = db.transaction('entries', 'readonly');
    final result = <StoredText>[];
    await for (final cursor in transaction.objectStore('entries').openCursor(autoAdvance: true)) {
      final key = cursor.key as String;
      if (!key.startsWith('$group/')) continue;
      final entry = Map<String, dynamic>.from(cursor.value as Map);
      result.add(StoredText(key.substring(group.length + 1), entry['content'] as String,
          DateTime.fromMillisecondsSinceEpoch(entry['modified'] as int)));
    }
    return result;
  }

  @override
  Future<void> delete(String group, String name) async {
    final db = await database;
    final transaction = db.transaction('entries', 'readwrite');
    final completed = transaction.completed;
    await transaction.objectStore('entries').delete(_key(group, name));
    await completed;
  }

  @override
  Future<void> move(String from, String to, String name) async {
    final entry = await read(from, name);
    if (entry == null) throw StateError('Save not found: $name');
    await write(to, name, entry.content);
    await delete(from, name);
  }
}
