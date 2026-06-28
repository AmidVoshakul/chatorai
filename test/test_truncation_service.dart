import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/truncation_service.dart';

void main() {
  group('TruncationService.compute — no truncation needed', () {
    test('returns original text when within limits', () {
      final text = 'short text\nsecond line';
      final result = TruncationService.compute(text);
      expect(result.truncated, isFalse);
      expect(result.content, text);
      expect(result.outputPath, isNull);
    });

    test('empty string is not truncated', () {
      final result = TruncationService.compute('');
      expect(result.truncated, isFalse);
      expect(result.content, '');
    });

    test('text exactly at maxLines boundary is not truncated', () {
      final lines = List.generate(2000, (i) => 'line $i').join('\n');
      final result = TruncationService.compute(lines);
      expect(result.truncated, isFalse);
    });

    test('text exactly at maxBytes boundary is not truncated', () {
      final text = 'x' * (50 * 1024); // exactly 50 KB
      final result = TruncationService.compute(text);
      expect(result.truncated, isFalse);
    });
  });

  group('TruncationService.compute — line-based truncation (head)', () {
    test('truncates when line count exceeds maxLines', () {
      final lines = List.generate(3000, (i) => 'line $i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(maxLines: 2000, maxBytes: 50000),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('lines truncated'));
      expect(result.content, contains('line 0'));
    });

    test('head direction keeps first lines', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(
          maxLines: 3,
          maxBytes: 50000,
          direction: 'head',
        ),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('L0'));
      expect(result.content, contains('L2'));
      expect(result.content, isNot(contains('L9')));
    });

    test('tail direction keeps last lines', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(
          maxLines: 3,
          maxBytes: 50000,
          direction: 'tail',
        ),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('L7'));
      expect(result.content, contains('L9'));
      expect(result.content, isNot(contains('L0')));
    });

    test('tail output starts with truncation sentinel', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(
          maxLines: 3,
          maxBytes: 50000,
          direction: 'tail',
        ),
      );
      expect(result.content, startsWith('...'));
    });

    test('head output ends with truncation sentinel', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(
          maxLines: 3,
          maxBytes: 50000,
          direction: 'head',
        ),
      );
      expect(result.content, contains('lines truncated'));
    });
  });

  group('TruncationService.compute — byte-based truncation', () {
    test('truncates when byte count exceeds maxBytes', () {
      // Each line is ~100 bytes; 600 lines = ~60 KB > 50 KB limit
      final lines = List.generate(600, (i) => 'line-$i-${'x' * 80}').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(maxLines: 2000, maxBytes: 50 * 1024),
      );
      expect(result.truncated, isTrue);
      expect(result.content, contains('bytes truncated'));
    });

    test('UTF-8 multi-byte characters counted correctly', () {
      // Each 'é' is 2 bytes in UTF-8
      final text = 'é' * 30000; // 60 KB in UTF-8
      final result = TruncationService.compute(
        text,
        options: const TruncationOptions(maxLines: 2000, maxBytes: 50 * 1024),
      );
      expect(result.truncated, isTrue);
    });
  });

  group('TruncationService.compute — hint text', () {
    test('hasTaskTool hint mentions Task tool', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(maxLines: 3, maxBytes: 50000),
        hasTaskTool: true,
      );
      expect(result.content, contains('Task tool'));
      expect(result.content, contains('explore agent'));
    });

    test('no hasTaskTool hint mentions Grep', () {
      final lines = List.generate(10, (i) => 'L$i').join('\n');
      final result = TruncationService.compute(
        lines,
        options: const TruncationOptions(maxLines: 3, maxBytes: 50000),
        hasTaskTool: false,
      );
      expect(result.content, contains('Grep'));
    });
  });

  group('TruncationService.truncate (legacy midpoint)', () {
    test('returns original when within 50000 chars', () {
      final text = 'x' * 1000;
      final result = TruncationService.instance.truncate(text);
      expect(result, text);
    });

    test('truncates when exceeding 50000 chars', () {
      final text = 'x' * 60000;
      final result = TruncationService.instance.truncate(text);
      expect(result.length, lessThan(60000));
      expect(result, contains('lines truncated'));
    });

    test('preserves head and tail of long output', () {
      final head = 'HEAD_MARKER';
      final tail = 'TAIL_MARKER';
      final middle = 'x' * 60000;
      final text = '$head$middle$tail';
      final result = TruncationService.instance.truncate(text);
      expect(result, contains('HEAD_MARKER'));
      expect(result, contains('TAIL_MARKER'));
    });

    test('empty string is returned as-is', () {
      final result = TruncationService.instance.truncate('');
      expect(result, '');
    });

    test('exactly 50000 chars is not truncated', () {
      final text = 'x' * 50000;
      final result = TruncationService.instance.truncate(text);
      expect(result, text);
    });
  });

  group('TruncationResult', () {
    test('toString is informative', () {
      const r = TruncationResult(content: 'abc', truncated: false);
      expect(r.content, 'abc');
      expect(r.truncated, isFalse);
      expect(r.outputPath, isNull);
    });

    test('truncated result with path', () {
      const r = TruncationResult(
        content: 'preview',
        truncated: true,
        outputPath: '/tmp/full.txt',
      );
      expect(r.truncated, isTrue);
      expect(r.outputPath, '/tmp/full.txt');
    });
  });

  group('TruncationOptions', () {
    test('default direction is head', () {
      const opts = TruncationOptions();
      expect(opts.direction, 'head');
      expect(opts.maxLines, isNull);
      expect(opts.maxBytes, isNull);
    });

    test('custom options', () {
      const opts = TruncationOptions(
        maxLines: 100,
        maxBytes: 1024,
        direction: 'tail',
      );
      expect(opts.maxLines, 100);
      expect(opts.maxBytes, 1024);
      expect(opts.direction, 'tail');
    });
  });
}
