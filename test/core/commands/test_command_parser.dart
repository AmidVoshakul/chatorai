import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/commands/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final subagent = AgentDefinition(
    id: 'explore',
    name: 'explore',
    mode: AgentMode.subagent,
  );
  final primary = AgentDefinition(
    id: 'build',
    name: 'build',
    mode: AgentMode.primary,
  );

  group('isSubtaskRule', () {
    test('subagent target defaults to subtask execution', () {
      expect(isSubtaskRule(subagent, null), isTrue);
    });

    test('subtask true keeps subagent on task path', () {
      expect(isSubtaskRule(subagent, true), isTrue);
    });

    test('subtask false opts out of subtask execution', () {
      expect(isSubtaskRule(subagent, false), isFalse);
    });

    test('subtask true forces task path even for primary agents', () {
      expect(isSubtaskRule(primary, true), isTrue);
    });

    test('primary agent without explicit flag stays inline', () {
      expect(isSubtaskRule(primary, null), isFalse);
      expect(isSubtaskRule(primary, false), isFalse);
    });
  });

  group('resolveCommandTarget', () {
    test('explicit target wins over fallback', () {
      expect(resolveCommandTarget(subagent, primary).id, 'explore');
    });

    test('fallback used when no agent declared', () {
      expect(resolveCommandTarget(null, primary).id, 'build');
    });
  });

  group('CommandParser.parse', () {
    test('parses full frontmatter and body', () {
      const content = '''
---
description: Review current changes
agent: explore
model: gpt-4o
variant: fast
subtask: true
---
Review the diff carefully.
''';
      final cmd = CommandParser.parse('commands/review.md', content);

      expect(cmd.name, 'review');
      expect(cmd.template, 'Review the diff carefully.');
      expect(cmd.description, 'Review current changes');
      expect(cmd.agent, 'explore');
      expect(cmd.model, 'gpt-4o');
      expect(cmd.variant, 'fast');
      expect(cmd.subtask, isTrue);
    });

    test('description, agent, model, variant, subtask are optional', () {
      const content = '''
---
description: Just do it
---
Do it now.
''';
      final cmd = CommandParser.parse('commands/do-it.md', content);

      expect(cmd.name, 'do-it');
      expect(cmd.template, 'Do it now.');
      expect(cmd.agent, isNull);
      expect(cmd.model, isNull);
      expect(cmd.variant, isNull);
      expect(cmd.subtask, isNull);
    });

    test('derives nested name from entry path', () {
      const content = '---\ndescription: x\n---\nbody';
      final cmd = CommandParser.parse('commands/fe/review.md', content);
      expect(cmd.name, 'fe/review');
    });

    test('accepts singular command/ prefix', () {
      const content = '---\ndescription: x\n---\nbody';
      final cmd = CommandParser.parse('command/deploy.md', content);
      expect(cmd.name, 'deploy');
    });

    test('normalizes windows separators', () {
      const content = '---\ndescription: x\n---\nbody';
      final cmd = CommandParser.parse('commands\\fe\\review.md', content);
      expect(cmd.name, 'fe/review');
    });

    test('falls back to basename without known prefix', () {
      const content = '---\ndescription: x\n---\nbody';
      final cmd = CommandParser.parse('other/tool.md', content);
      expect(cmd.name, 'tool');
    });

    test('throws on missing frontmatter delimiters', () {
      expect(
        () => CommandParser.parse('commands/x.md', 'no frontmatter'),
        throwsFormatException,
      );
    });

    test('throws on invalid yaml', () {
      const content = '---\n{{{[[\n---\nbody';
      expect(
        () => CommandParser.parse('commands/x.md', content),
        throwsFormatException,
      );
    });

    test('throws on empty template body', () {
      const content = '---\ndescription: x\n---\n';
      expect(
        () => CommandParser.parse('commands/x.md', content),
        throwsFormatException,
      );
    });

    test('throws on empty command name', () {
      const content = '---\ndescription: x\n---\nbody';
      expect(
        () => CommandParser.parse('commands/.md', content),
        throwsFormatException,
      );
    });
  });

  group('matchModelId', () {
    final ids = {'openai/gpt-4o', 'openai/gpt-4o-mini', 'anthropic/claude-3'};

    test('exact id matches directly', () {
      expect(matchModelId(ids, 'openai/gpt-4o'), 'openai/gpt-4o');
    });

    test('bare name resolves via unique provider suffix', () {
      expect(matchModelId(ids, 'claude-3'), 'anthropic/claude-3');
    });

    test('ambiguous bare name returns null', () {
      final ambiguous = {...ids, 'azure/gpt-4o'};
      expect(matchModelId(ambiguous, 'gpt-4o'), isNull);
    });

    test('unknown name returns null', () {
      expect(matchModelId(ids, 'mistral/large'), isNull);
      expect(matchModelId(ids, ''), isNull);
    });
  });

  group('buildSubtaskResultNote', () {
    test('contains agent, title, delimited output and continuation ask', () {
      final note = buildSubtaskResultNote(
        agentName: 'general',
        taskTitle: 'Say hello',
        output: 'hello!',
      );

      expect(note, contains('[SUBTASK RESULT]'));
      expect(note, contains('agent: general'));
      expect(note, contains('task: Say hello'));
      expect(note, contains('--- begin output ---'));
      expect(note, contains('hello!'));
      expect(note, contains('--- end output ---'));
      expect(note, contains('Continue answering the user'));
    });

    test('keeps multi-line output verbatim between markers', () {
      final note = buildSubtaskResultNote(
        agentName: 'explore',
        taskTitle: 'Scan',
        output: 'line1\nline2\n\nline4',
      );

      final begin = note.indexOf('--- begin output ---');
      final end = note.indexOf('--- end output ---');
      expect(begin, greaterThanOrEqualTo(0));
      expect(end, greaterThan(begin));
      expect(
        note.substring(begin + '--- begin output ---'.length, end).trim(),
        'line1\nline2\n\nline4',
      );
    });
  });

  group('commandHints', () {
    test('extracts numbered placeholders sorted', () {
      final hints = commandHints(r'Use $2 then $1 again');
      expect(hints, [r'$1', r'$2']);
    });

    test('deduplicates placeholders', () {
      final hints = commandHints(r'$1 and $1 and $2');
      expect(hints, [r'$1', r'$2']);
    });

    test('detects ARGUMENTS placeholder', () {
      final hints = commandHints(r'Run with $ARGUMENTS');
      expect(hints, [r'$ARGUMENTS']);
    });

    test('returns empty for plain template', () {
      expect(commandHints('plain text'), isEmpty);
    });
  });

  group('expandCommandTemplate', () {
    test('substitutes positional arguments', () {
      final out = expandCommandTemplate(r'fix $1 in $2', 'login app.dart');
      expect(out, 'fix login in app.dart');
    });

    test('last placeholder consumes remaining arguments', () {
      final out = expandCommandTemplate(r'move $1 to $2', 'a b c d');
      expect(out, 'move a to b c d');
    });

    test('missing positional argument becomes empty', () {
      final out = expandCommandTemplate(r'fix $1 in $2', 'login');
      expect(out, 'fix login in');
    });

    test('expands ARGUMENTS placeholder with raw text', () {
      final out = expandCommandTemplate(r'run for $ARGUMENTS', 'a  b');
      expect(out, 'run for a  b');
    });

    test('appends arguments when template has no placeholders', () {
      final out = expandCommandTemplate('summarize this', 'extra notes');
      expect(out, 'summarize this\n\nextra notes');
    });

    test('keeps template as-is when no placeholders and no arguments', () {
      final out = expandCommandTemplate('summarize this', '   ');
      expect(out, 'summarize this');
    });

    test('zero placeholder contributes nothing instead of throwing', () {
      final out = expandCommandTemplate(r'echo $0', 'hello');
      expect(out, 'echo');
    });

    test('zero placeholder leaves valid neighbors substituted', () {
      final out = expandCommandTemplate(r'Use $0 and $1', 'alpha beta');
      expect(out, 'Use  and alpha beta');
    });
  });
}
