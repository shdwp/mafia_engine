class StoredText {
  final String name;
  final String content;
  final DateTime modified;

  const StoredText(this.name, this.content, this.modified);
}

abstract class AppStorage {
  Future<StoredText?> read(String group, String name);
  Future<void> write(String group, String name, String content);
  Future<List<StoredText>> list(String group);
  Future<void> delete(String group, String name);
  Future<void> move(String from, String to, String name);
}
