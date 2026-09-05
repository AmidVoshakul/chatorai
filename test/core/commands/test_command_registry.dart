import 'dart:io';

import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/command_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<Directory> _writeTree(
  Directory tmp,
  String relDir, {
  Map<String, String> files = const {},
}) async {
  final root = Directory(p.join(tmp.path, relDir));
  for (final entry in files.entries) {
    final f = File(p.join(root.path, entry.key));
    await f.create(recursive: true);
    await f.writeAsString(entry.value);
  }
  return root;
}

const _cmd = '---\ndescription: %DESC%\n---\nbody of %NAME%';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('commands_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('CommandRegistry.load', () {
    test('loads from plural and singular dirs recursively', () async {
      final global = await _writeTree(
        tmp,
        'global',
        files: {
          'commands/review.md': _cmd
              .replaceAll('%DESC%', 'review cmd')
              .replaceAll('%NAME%', 'review'),
          'command/deploy.md': _cmd
              .replaceAll('%DESC%', 'deploy cmd')
              .replaceAll('%NAME%', 'deploy'),
          'commands/nested/audit.md': _cmd
              .replaceAll('%DESC%', 'audit cmd')
              .replaceAll('%NAME%', 'audit'),
        },
      );

      final loaded = await CommandRegistry.load([global.path]);

      expect(loaded.keys, containsAll(['review', 'deploy', 'nested/audit']));
      expect(loaded['review']!.description, 'review cmd');
      expect(loaded['nested/audit']!.template, 'body of audit');
    });

    test('ignores non-markdown files', () async {
      final global = await _writeTree(
        tmp,
        'global',
        files: {
          'commands/a.md': '---\ndescription: a\n---\nA',
          'commands/notes.txt': 'not markdown',
          'README.md': 'readme',
        },
      );

      final loaded = await CommandRegistry.load([global.path]);

      expect(loaded.keys, ['a']);
    });

    test('later root overrides earlier root (project wins)', () async {
      final global = await _writeTree(
        tmp,
        'global',
        files: {
          'commands/review.md': '---\ndescription: global\n---\nglobal body',
          'commands/only-global.md':
              '---\ndescription: g\n---\nonly global body',
        },
      );
      final project = await _writeTree(
        tmp,
        'project',
        files: {
          'commands/review.md': '---\ndescription: project\n---\nproject body',
        },
      );

      final loaded = await CommandRegistry.load([global.path, project.path]);

      expect(loaded['review']!.description, 'project');
      expect(loaded['review']!.template, 'project body');
      expect(loaded.keys, contains('only-global'));
    });

    test('skips malformed files without failing the load', () async {
      final global = await _writeTree(
        tmp,
        'global',
        files: {
          'commands/good.md': '---\ndescription: ok\n---\nfine',
          'commands/bad.md': 'no frontmatter here',
        },
      );

      final loaded = await CommandRegistry.load([global.path]);

      expect(loaded.keys, ['good']);
    });

    test('returns empty map when roots are missing', () async {
      final loaded = await CommandRegistry.load([
        p.join(tmp.path, 'missing-a'),
        p.join(tmp.path, 'missing-b'),
      ]);

      expect(loaded, isEmpty);
    });

    test('does not let one root see entries of another prefix depth', () async {
      // A file at <root>/commands.md (a FILE named commands) must not crash
      // the scan and must be ignored.
      final global = await _writeTree(
        tmp,
        'global',
        files: {'commands/a.md': '---\ndescription: a\n---\nA'},
      );
      await File(
        p.join(global.path, 'commands.md'),
      ).writeAsString('stray file');

      final loaded = await CommandRegistry.load([global.path]);

      expect(loaded.keys, ['a']);
    });

    test('file definitions override same-named JSON entries', () async {
      final global = await _writeTree(
        tmp,
        'global',
        files: {'commands/review.md': '---\ndescription: file\n---\nfile body'},
      );

      final loaded = await CommandRegistry.load(
        [global.path],
        fromJson: {
          'review': const CommandInfo(
            name: 'review',
            template: 'json body',
            description: 'json',
          ),
          'only-json': const CommandInfo(name: 'only-json', template: 'json'),
        },
      );

      expect(loaded['review']!.description, 'file');
      expect(loaded['review']!.template, 'file body');
      expect(loaded['only-json']!.template, 'json');
      expect(loaded.length, 2);
    });
  });
}
