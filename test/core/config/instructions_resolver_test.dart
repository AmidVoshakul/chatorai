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

      final resolver = InstructionsResolver();
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
  });
}
