import 'dart:io';

import 'package:chatorai/shared/utils/chatorai_roots.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('chatorai_roots_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('projectChatoraiRoots', () {
    test(
      'collects only ancestors containing .chatorai, topmost first',
      () async {
        final repo = Directory(p.join(tmp.path, 'repo'));
        final deep = Directory(p.join(repo.path, 'sub', 'deep'));
        await deep.create(recursive: true);
        Directory(p.join(repo.path, '.chatorai')).createSync();
        Directory(p.join(deep.path, '.chatorai')).createSync();

        final roots = projectChatoraiRoots(start: deep.path);

        expect(roots, [
          p.join(repo.path, '.chatorai'),
          p.join(deep.path, '.chatorai'),
        ]);
      },
    );

    test('stops the walk after the .git worktree boundary', () async {
      final outside = Directory(p.join(tmp.path, 'outside'));
      final repo = Directory(p.join(tmp.path, 'repo'));
      final deep = Directory(p.join(repo.path, 'sub'));
      await deep.create(recursive: true);
      await outside.create();
      Directory(p.join(outside.path, '.chatorai')).createSync();
      Directory(p.join(repo.path, '.git')).createSync();
      Directory(p.join(repo.path, '.chatorai')).createSync();

      final roots = projectChatoraiRoots(start: deep.path);

      // `outside` is above the .git boundary and must not be included.
      expect(roots, [p.join(repo.path, '.chatorai')]);
    });

    test('supports .git as a file (worktrees/submodules)', () async {
      final repo = Directory(p.join(tmp.path, 'repo'));
      await repo.create(recursive: true);
      File(p.join(repo.path, '.git')).writeAsStringSync('gitdir: ...');
      Directory(p.join(repo.path, '.chatorai')).createSync();

      final roots = projectChatoraiRoots(start: repo.path);

      expect(roots, [p.join(repo.path, '.chatorai')]);
    });

    test('returns empty when no ancestor has .chatorai', () async {
      final plain = Directory(p.join(tmp.path, 'a', 'b'));
      await plain.create(recursive: true);

      expect(projectChatoraiRoots(start: plain.path), isEmpty);
    });
  });
}
