import 'dart:io';

import 'package:chatorai/core/commands/command_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late String root;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('command_service_test');
    root = p.join(tmp.path, 'root');
    final commandsDir = Directory(p.join(root, 'commands'));
    await commandsDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> writeCommand(String relPath, String body) async {
    final file = File(p.join(root, 'commands', relPath));
    await file.create(recursive: true);
    await file.writeAsString('---\ndescription: $relPath\n---\n$body');
  }

  test('listAll caches and getByName resolves nested names', () async {
    await writeCommand('review.md', 'review body');
    await writeCommand(p.join('fe', 'audit.md'), 'audit body');

    final service = CommandService(roots: [root]);

    expect((await service.listAll()).length, 2);
    expect((await service.getByName('fe/audit'))!.template, 'audit body');
    expect(await service.getByName('missing'), isNull);
    service.dispose();
  });

  test('reloads after a watched file changes', () async {
    await writeCommand('review.md', 'v1');
    final service = CommandService(roots: [root]);
    expect((await service.listAll()).length, 1);

    // Trigger the watcher through the real filesystem event path.
    var changed = false;
    // ignore: invalid_use_of_protected_member
    final file = File(p.join(root, 'commands', 'review.md'));
    await file.writeAsString('---\ndescription: review.md\n---\nv2');

    // Watcher debounce is 250ms; poll up to 5s for the reload to land.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final current = await service.listAll();
      if (current.isNotEmpty && current.first.template == 'v2') {
        changed = true;
        break;
      }
    }
    expect(changed, isTrue);
    service.dispose();
  });

  test('picks up newly created files without restart', () async {
    final service = CommandService(roots: [root]);
    expect(await service.listAll(), isEmpty);

    await writeCommand('fresh.md', 'fresh body');
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    var found = false;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if ((await service.listAll()).isNotEmpty) {
        found = true;
        break;
      }
    }
    expect(found, isTrue);
    expect((await service.getByName('fresh'))!.template, 'fresh body');
    service.dispose();
  });
}
