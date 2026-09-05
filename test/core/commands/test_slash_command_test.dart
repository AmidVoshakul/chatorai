import 'package:chatorai/core/commands/slash_command.dart';
import 'package:test/test.dart';

void main() {
  group('SlashCommand', () {
    test('creates with required fields', () {
      const cmd = SlashCommand('/help', 'Show help');
      expect(cmd.name, '/help');
      expect(cmd.description, 'Show help');
      expect(cmd.template, isNull);
      expect(cmd.hints, isEmpty);
    });

    test('creates with optional fields', () {
      const cmd = SlashCommand(
        '/review',
        'Review code',
        template: 'Review \$1',
        agent: 'reviewer',
        model: 'gpt-4',
        variant: 'fast',
        subtask: true,
        hints: [r'$1'],
      );
      expect(cmd.template, 'Review \$1');
      expect(cmd.agent, 'reviewer');
      expect(cmd.model, 'gpt-4');
      expect(cmd.variant, 'fast');
      expect(cmd.subtask, isTrue);
      expect(cmd.hints, [r'$1']);
    });

    test('equality', () {
      const a = SlashCommand('/help', 'Show help');
      const b = SlashCommand('/help', 'Show help');
      const c = SlashCommand('/clear', 'Clear chat');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode consistent with equality', () {
      const a = SlashCommand('/help', 'Show help');
      const b = SlashCommand('/help', 'Show help');
      expect(a.hashCode, b.hashCode);
    });
  });
}
