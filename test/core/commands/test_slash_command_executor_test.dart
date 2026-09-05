import 'package:chatorai/core/commands/slash_command.dart';
import 'package:chatorai/core/commands/slash_command_executor.dart';
import 'package:test/test.dart';

void main() {
  group('SlashCommandExecutor', () {
    test('handles /thinking by toggling expandReasoning', () async {
      var toggledValue;
      var cleared = false;
      final ctx = SlashCommandExecutorContext(
        expandReasoningCurrent: false,
        onSetExpandReasoning: (v) => toggledValue = v,
        clearInput: () => cleared = true,
      );
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/thinking', ''),
        ctx,
      );
      expect(result.handled, isTrue);
      expect(toggledValue, isTrue);
      expect(cleared, isTrue);
    });

    test('handles /thinking toggle from true to false', () async {
      var toggledValue;
      final ctx = SlashCommandExecutorContext(
        expandReasoningCurrent: true,
        onSetExpandReasoning: (v) => toggledValue = v,
        clearInput: () {},
      );
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/thinking', ''),
        ctx,
      );
      expect(result.handled, isTrue);
      expect(toggledValue, isFalse);
    });

    test('handles /new by creating new chat and clearing', () async {
      var created = false;
      var cleared = false;
      final ctx = SlashCommandExecutorContext(
        onCreateNewChat: () async => created = true,
        clearInput: () => cleared = true,
      );
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/new', ''),
        ctx,
      );
      expect(result.handled, isTrue);
      expect(created, isTrue);
      expect(cleared, isTrue);
    });

    test('handles /compact by calling onCompact and clearing', () async {
      var compacted = false;
      var cleared = false;
      final ctx = SlashCommandExecutorContext(
        onCompact: () async => compacted = true,
        clearInput: () => cleared = true,
      );
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/compact', ''),
        ctx,
      );
      expect(result.handled, isTrue);
      expect(compacted, isTrue);
      expect(cleared, isTrue);
    });

    test('returns not handled for other commands', () async {
      var compacted = false;
      final ctx = SlashCommandExecutorContext(
        onCompact: () async => compacted = true,
        clearInput: () {},
      );
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/help', ''),
        ctx,
      );
      expect(result.handled, isFalse);
      expect(compacted, isFalse);
    });

    test('handles /thinking without callbacks still returns handled', () async {
      final ctx = SlashCommandExecutorContext(expandReasoningCurrent: false);
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/thinking', ''),
        ctx,
      );
      expect(result.handled, isTrue);
    });

    test('is case-sensitive for command name', () async {
      final ctx = SlashCommandExecutorContext(clearInput: () {});
      final result = await SlashCommandExecutor.execute(
        const SlashCommand('/THINKING', ''),
        ctx,
      );
      expect(result.handled, isFalse);
    });
  });
}
