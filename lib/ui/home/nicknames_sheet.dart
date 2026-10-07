import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mafia_engine/data/game_repository.dart';
import 'package:provider/provider.dart';

class NicknamesSheet extends StatefulWidget {
  const NicknamesSheet({super.key});

  @override
  State<NicknamesSheet> createState() => _NicknamesSheetState();
}

class _NicknamesSheetState extends State<NicknamesSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parse(String text) => text
      .split(RegExp(r'\r?\n'))
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _reload() async {
    final names = await context.read<GameRepository>().getPlayerNames();
    if (mounted) _controller.text = names.join('\n');
  }

  Future<void> _clear() async {
    await context.read<GameRepository>().clearPlayerNames();
    if (mounted) _controller.clear();
  }

  Future<void> _import() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final names = _parse('${_controller.text}\n${data!.text}');
    await context.read<GameRepository>().replacePlayerNames(names);
    if (mounted) _controller.text = names.join('\n');
  }

  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: _parse(_controller.text).join('\n')));
  }

  Future<void> _save() async {
    final names = _parse(_controller.text);
    await context.read<GameRepository>().replacePlayerNames(names);
    if (mounted) _controller.text = names.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            FilledButton(onPressed: _import, child: const Text('Import')),
            OutlinedButton(onPressed: _export, child: const Text('Export')),
          ],
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'One nickname per line',
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            TextButton(onPressed: _clear, child: const Text('Clear database')),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ],
    );
  }
}
