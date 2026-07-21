import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';

void main() {
  setUp(() async {
    await XdgPaths.init();
  });

  group('TruncationService.compute', () {
    test('returns untruncated result when within limits', () {
      final text = 'hello world';
      final result = TruncationService.compute(text);
      expect(result.content, equals(text));
      expect(result.truncated, isFalse);
    });

    test('truncates with head direction when exceeding maxLines', () {
      final text = List.generate(3000, (i) => 'line $i').join('\n');
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(maxLines: 10, maxBytes: 999999),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('lines truncated'));
      expect(result.outputPath, isNull);
    });

    test('truncates when exceeding maxBytes', () {
      final text = 'a' * 100000;
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(maxBytes: 100),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('bytes truncated'));
      expect(result.outputPath, isNull);
    });

    test('tail direction preserves last lines', () {
      final lines = List.generate(100, (i) => 'line $i');
      final text = lines.join('\n');
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(
          maxLines: 5,
          maxBytes: 999999,
          direction: 'tail',
        ),
      );
      expect(result.truncated, isTrue);
      // tail keeps last 5 lines: 96-99
      expect(result.content, contains('line 99'));
      expect(result.content, contains('line 95'));
      // head lines should not appear
      expect(result.content, isNot(contains('line 0')));
    });

    test('head direction is the default', () {
      final lines = List.generate(100, (i) => 'line $i');
      final text = lines.join('\n');
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(maxLines: 5, maxBytes: 999999),
      );
      // head keeps first 5 lines: 0-4
      expect(result.content, contains('line 0'));
      expect(result.content, contains('line 4'));
      expect(result.content, isNot(contains('line 99')));
    });

    test('hasTaskTool=true adds Task tool delegation hint', () {
      final text = List.generate(3000, (i) => 'line $i').join('\n');
      final result = TruncationService.compute(text, hasTaskTool: true);
      expect(result.content, contains('Task tool'));
      expect(result.content, contains('explore agent'));
    });

    test('hasTaskTool=false adds Grep/Read hint', () {
      final text = List.generate(3000, (i) => 'line $i').join('\n');
      final result = TruncationService.compute(text, hasTaskTool: false);
      expect(result.content, contains('Grep'));
      expect(result.content, contains('Read with offset'));
    });

    test('head hint format places preview before sentinel', () {
      final result = TruncationService.compute(
        'line0\nline1\nline2',
        options: const TruncationOptions(maxLines: 1, maxBytes: 999999),
      );
      expect(result.content, contains('line0'));
      final sentinelIdx = result.content.indexOf('truncated');
      final previewIdx = result.content.indexOf('line0');
      expect(previewIdx, lessThan(sentinelIdx));
    });

    test('tail hint format places sentinel before preview', () {
      final result = TruncationService.compute(
        'line0\nline1\nline2',
        options: const TruncationOptions(
          maxLines: 1,
          maxBytes: 999999,
          direction: 'tail',
        ),
      );
      expect(result.content, contains('line2'));
      final sentinelIdx = result.content.indexOf('truncated');
      final previewIdx = result.content.indexOf('line2');
      expect(sentinelIdx, lessThan(previewIdx));
    });

    test('byte counts match UTF-8 encoding', () {
      final text = 'ééé'; // 2 bytes per char in UTF-8
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(maxBytes: 3, maxLines: 999999),
      );
      // 3 bytes allows only 1 'é' (2 bytes) plus 1 byte for newline? No, single line is 6 bytes total, so 6 > 3, should truncate
      expect(result.truncated, isTrue);
      expect(result.content, contains('bytes truncated'));
    });

    test('returns untruncated for empty string', () {
      final result = TruncationService.compute('');
      expect(result.truncated, isFalse);
      expect(result.content, equals(''));
    });

    test('returns untruncated for single line within limits', () {
      final result = TruncationService.compute('single line');
      expect(result.truncated, isFalse);
    });
  });

  group('TruncationService (file I/O)', () {
    test(
      'cleanup does not throw even if the data directory is unavailable',
      () async {
        final service = TruncationService.instance;
        await expectLater(service.cleanup(), completes);
      },
    );

    test(
      'writes overflow to the data tool-output directory, not Documents',
      () async {
        final service = TruncationService.instance;
        final big = 'x' * (60 * 1024);
        final result = await service.output(big);
        expect(result.truncated, isTrue);
        expect(result.outputPath, isNotNull);
        final dataDir = XdgPaths.dataSubdirSync('tool-output').path;
        expect(result.outputPath, startsWith(dataDir));
        expect(result.outputPath, isNot(contains('Documents')));
      },
    );
  });

  group('TruncationService legacy', () {
    test('truncate returns unchanged when within _maxOutputChars', () {
      final service = TruncationService.instance;
      expect(service.truncate('small text'), equals('small text'));
    });

    test('truncate does midpoint cut with sentinel when over limit', () {
      final service = TruncationService.instance;
      final text = 'a' * 100000;
      final result = service.truncate(text);
      expect(result.length, lessThan(text.length));
      expect(result, contains('truncated'));
    });
  });

  group('TruncationOptions', () {
    test('defaults are head directive with maxLines and maxBytes', () {
      final opts = TruncationService.instance.limits();
      expect(opts.maxLines, equals(2000));
      expect(opts.maxBytes, equals(50 * 1024));
      expect(opts.direction, equals('head'));
    });

    test('custom values are preserved', () {
      const opts = TruncationOptions(
        maxLines: 100,
        maxBytes: 5000,
        direction: 'tail',
      );
      expect(opts.maxLines, 100);
      expect(opts.maxBytes, 5000);
      expect(opts.direction, 'tail');
    });
  });

  group('TruncationResult', () {
    test('constructs with required fields', () {
      const r = TruncationResult(content: 'hello', truncated: false);
      expect(r.content, 'hello');
      expect(r.truncated, isFalse);
      expect(r.outputPath, isNull);
    });

    test('includes outputPath when truncated', () {
      const r = TruncationResult(
        content: 'truncated',
        truncated: true,
        outputPath: '/tmp/out.txt',
      );
      expect(r.outputPath, equals('/tmp/out.txt'));
    });
  });
}
