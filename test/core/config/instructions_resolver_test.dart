import 'dart:io';

import 'package:chatorai/core/config/instructions_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// A minimal [http.Client] stub returning a fixed body for any GET.
class _StubClient extends http.BaseClient {
  _StubClient(this._body);
  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = _body.codeUnits;
    return http.StreamedResponse(
      Stream.value(List<int>.from(bytes)),
      200,
      request: request,
    );
  }
}

void main() {
  group('InstructionsResolver', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('instr_test_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('resolves relative glob from cwd', () async {
      await File(p.join(tmp.path, 'a.md')).writeAsString('AAA');
      await File(p.join(tmp.path, 'b.md')).writeAsString('BBB');

      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(tmp.path, '*.md'),
      ], cwd: tmp);
      expect(blocks, hasLength(2));
      expect(blocks.join('\n'), contains('AAA'));
      expect(blocks.join('\n'), contains('BBB'));
    });

    test('resolves recursive glob (**/*.md)', () async {
      await File(p.join(tmp.path, 'a.md')).writeAsString('AAA');
      final dir = Directory(p.join(tmp.path, 'sub'))..createSync();
      await File(p.join(dir.path, 'c.md')).writeAsString('CCC');

      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(tmp.path, '**.md'),
      ], cwd: tmp);
      expect(blocks, hasLength(2));
      expect(blocks.join('\n'), contains('AAA'));
      expect(blocks.join('\n'), contains('CCC'));
    });

    test('searches filename upward from cwd (first match wins)', () async {
      final parent = Directory(p.join(tmp.path, 'lvl1'))..createSync();
      final child = Directory(p.join(parent.path, 'lvl2'))..createSync();
      await File(p.join(parent.path, 'AGENTS.md')).writeAsString('PARENT');
      await File(p.join(child.path, 'AGENTS.md')).writeAsString('CHILD');

      // Disable auto-discovery to test explicit entry behavior only.
      final resolver = InstructionsResolver(disableProjectConfig: true);
      final blocks = await resolver.resolve(['AGENTS.md'], cwd: child);
      expect(blocks, hasLength(1));
      expect(blocks.single, contains('CHILD'));
    });

    test('expands ~/ to home', () async {
      final homeFile = File(p.join(tmp.path, 'home_instr.md'));
      await homeFile.writeAsString('HOME');
      // Point home at tmp via a resolver with explicit home.
      final resolver = InstructionsResolver(home: tmp.path);
      final blocks = await resolver.resolve(['~/home_instr.md'], cwd: tmp);
      expect(blocks, hasLength(1));
      expect(blocks.single, contains('HOME'));
      expect(homeFile.existsSync(), isTrue);
    });

    test('deduplicates repeated entries', () async {
      await File(p.join(tmp.path, 'dup.md')).writeAsString('DUP');
      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(tmp.path, 'dup.md'),
        p.join(tmp.path, 'dup.md'),
      ], cwd: tmp);
      expect(blocks, hasLength(1));
    });

    test('fetches http(s) URL', () async {
      final client = _StubClient('REMOTE RULES');
      final resolver = InstructionsResolver(httpClient: client);
      final blocks = await resolver.resolve([
        'https://example.com/rules.md',
      ], cwd: tmp);
      expect(blocks, hasLength(1));
      expect(blocks.single, contains('REMOTE RULES'));
      expect(blocks.single, contains('https://example.com/rules.md'));
      client.close();
    });

    test('skips missing entries without throwing', () async {
      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(tmp.path, 'nope.md'),
      ], cwd: tmp);
      expect(blocks, isEmpty);
    });

    test('blocks path traversal outside project root', () async {
      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve(['../../etc/passwd'], cwd: tmp);
      expect(blocks, isEmpty);
    });

    test('blocks private/loopback URL (SSRF guard)', () async {
      final client = _StubClient('SECRET');
      final resolver = InstructionsResolver(httpClient: client);
      final blocks = await resolver.resolve([
        'http://localhost:8080/secret',
      ], cwd: tmp);
      expect(blocks, isEmpty);
      client.close();
    });

    test('blocks non-http(s) schemes', () async {
      final client = _StubClient('DATA');
      final resolver = InstructionsResolver(httpClient: client);
      final blocks = await resolver.resolve(['file:///etc/passwd'], cwd: tmp);
      expect(blocks, isEmpty);
      client.close();
    });

    test('skips oversized files', () async {
      final big = File(p.join(tmp.path, 'big.md'));
      await big.writeAsString('x' * (3 * 1024 * 1024));
      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(tmp.path, 'big.md'),
      ], cwd: tmp);
      expect(blocks, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Auto-discovery tests
    // -------------------------------------------------------------------------

    test('auto-discovers AGENTS.md upward from cwd', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      final nested = Directory(p.join(project.path, 'src', 'lib'))
        ..createSync(recursive: true);
      await File(
        p.join(project.path, 'AGENTS.md'),
      ).writeAsString('PROJECT AGENTS');

      final resolver = InstructionsResolver();
      // Resolve with empty config — only auto-discovery should run.
      final blocks = await resolver.resolve([], cwd: nested);
      expect(blocks, isNotEmpty);
      expect(blocks.first, contains('PROJECT AGENTS'));
    });

    test('auto-discovers CLAUDE.md upward from cwd', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      await File(
        p.join(project.path, 'CLAUDE.md'),
      ).writeAsString('CLAUDE RULES');

      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([], cwd: project);
      expect(blocks, isNotEmpty);
      expect(blocks.first, contains('CLAUDE RULES'));
    });

    test(
      'auto-discovers both AGENTS.md and CLAUDE.md at different levels',
      () async {
        final project = Directory(p.join(tmp.path, 'project'))..createSync();
        final nested = Directory(p.join(project.path, 'src'))..createSync();
        await File(
          p.join(project.path, 'AGENTS.md'),
        ).writeAsString('PROJECT AGENTS');
        await File(
          p.join(nested.path, 'CLAUDE.md'),
        ).writeAsString('NESTED CLAUDE');

        final resolver = InstructionsResolver();
        final blocks = await resolver.resolve([], cwd: nested);
        expect(blocks, hasLength(2));
        // Project-level first (closest to root), then nested (closest to cwd).
        expect(blocks[0], contains('PROJECT AGENTS'));
        expect(blocks[1], contains('NESTED CLAUDE'));
      },
    );

    test('deduplicates auto-discovered and explicit entries', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      await File(
        p.join(project.path, 'AGENTS.md'),
      ).writeAsString('AUTO DISCOVERED');

      final resolver = InstructionsResolver();
      // Explicit entry should not duplicate the auto-discovered one.
      final blocks = await resolver.resolve(['AGENTS.md'], cwd: project);
      // Only one block for AGENTS.md.
      expect(blocks.where((b) => b.contains('AUTO DISCOVERED')), hasLength(1));
    });

    test('respects disableProjectConfig parameter', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      await File(
        p.join(project.path, 'AGENTS.md'),
      ).writeAsString('SHOULD NOT APPEAR');

      final resolver = InstructionsResolver(disableProjectConfig: true);
      final blocks = await resolver.resolve([], cwd: project);
      expect(blocks, isEmpty);
    });

    test('explicit entries still work alongside auto-discovery', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      await File(p.join(project.path, 'AGENTS.md')).writeAsString('AUTO');
      await File(p.join(project.path, 'extra.md')).writeAsString('EXPLICIT');

      final resolver = InstructionsResolver();
      final blocks = await resolver.resolve([
        p.join(project.path, 'extra.md'),
      ], cwd: project);
      expect(blocks, hasLength(2));
      expect(blocks.any((b) => b.contains('AUTO')), isTrue);
      expect(blocks.any((b) => b.contains('EXPLICIT')), isTrue);
    });
  });

  group('InstructionsResolver.discoverFiles', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('discover_test_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('lists global AGENTS.md first (editable, isGlobal)', () {
      final globalPath = p.join(tmp.path, 'global', 'AGENTS.md');
      final resolver = InstructionsResolver(disableProjectConfig: true);

      final files = resolver.discoverFiles(globalAgentsPath: globalPath);

      expect(files, hasLength(1));
      expect(files.first.name, 'AGENTS.md');
      expect(files.first.path, globalPath);
      expect(files.first.editable, isTrue);
      expect(files.first.isGlobal, isTrue);
      expect(files.first.exists, isFalse);
    });

    test('reports exists=true when the file is present', () async {
      final globalDir = Directory(p.join(tmp.path, 'global'))..createSync();
      final globalPath = p.join(globalDir.path, 'AGENTS.md');
      await File(globalPath).writeAsString('GLOBAL');
      final resolver = InstructionsResolver(disableProjectConfig: true);

      final files = resolver.discoverFiles(globalAgentsPath: globalPath);

      expect(files.single.exists, isTrue);
    });

    test(
      'discovers project AGENTS.md (editable) and CLAUDE.md (read-only)',
      () async {
        final project = Directory(p.join(tmp.path, 'project'))..createSync();
        await File(p.join(project.path, 'AGENTS.md')).writeAsString('A');
        await File(p.join(project.path, 'CLAUDE.md')).writeAsString('C');
        final resolver = InstructionsResolver();

        final files = resolver.discoverFiles(cwd: project);

        final agents = files.firstWhere((f) => f.name == 'AGENTS.md');
        final claude = files.firstWhere((f) => f.name == 'CLAUDE.md');
        expect(agents.editable, isTrue);
        expect(agents.isGlobal, isFalse);
        expect(claude.editable, isFalse);
        expect(claude.exists, isTrue);
      },
    );

    test('global entry precedes project entries', () async {
      final globalDir = Directory(p.join(tmp.path, 'global'))..createSync();
      final globalPath = p.join(globalDir.path, 'AGENTS.md');
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      await File(p.join(project.path, 'AGENTS.md')).writeAsString('A');
      final resolver = InstructionsResolver();

      final files = resolver.discoverFiles(
        cwd: project,
        globalAgentsPath: globalPath,
      );

      expect(files.first.isGlobal, isTrue);
      expect(
        files.any((f) => f.path == p.join(project.path, 'AGENTS.md')),
        isTrue,
      );
    });

    test('deduplicates when global path equals a discovered path', () async {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      final agentsPath = p.join(project.path, 'AGENTS.md');
      await File(agentsPath).writeAsString('A');
      final resolver = InstructionsResolver();

      final files = resolver.discoverFiles(
        cwd: project,
        globalAgentsPath: agentsPath,
      );

      expect(files.where((f) => f.path == agentsPath), hasLength(1));
    });

    test('returns only global entry when project config disabled', () {
      final project = Directory(p.join(tmp.path, 'project'))..createSync();
      File(p.join(project.path, 'AGENTS.md')).writeAsStringSync('A');
      final globalPath = p.join(tmp.path, 'global', 'AGENTS.md');
      final resolver = InstructionsResolver(disableProjectConfig: true);

      final files = resolver.discoverFiles(
        cwd: project,
        globalAgentsPath: globalPath,
      );

      expect(files, hasLength(1));
      expect(files.single.isGlobal, isTrue);
    });
  });
}
