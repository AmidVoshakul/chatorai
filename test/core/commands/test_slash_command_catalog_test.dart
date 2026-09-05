import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/slash_command.dart';
import 'package:chatorai/core/commands/slash_command_catalog.dart';
import 'package:test/test.dart';

class FakeLocalizations implements SlashCommandLocalizations {
  @override
  String get slashCommandSkills => 'Show skills';
  @override
  String get slashCommandNew => 'New chat';
  @override
  String get slashCommandClear => 'Clear';
  @override
  String get slashCommandCompact => 'Compact';
  @override
  String get slashCommandHelp => 'Help';
  @override
  String get slashCommandUndo => 'Undo';
  @override
  String get slashCommandRedo => 'Redo';
  @override
  String get slashCommandSessions => 'Sessions';
  @override
  String get slashCommandModels => 'Models';
  @override
  String get slashCommandTheme => 'Theme';
  @override
  String get slashCommandThinking => 'Thinking';
}

void main() {
  group('SlashCommandCatalog.builtIns', () {
    test('returns 11 built-in commands', () {
      final builtIns = SlashCommandCatalog.builtIns(null);
      expect(builtIns.length, 11);
      expect(
        builtIns.map((c) => c.name),
        containsAll([
          '/skills',
          '/new',
          '/clear',
          '/compact',
          '/help',
          '/undo',
          '/redo',
          '/sessions',
          '/models',
          '/theme',
          '/thinking',
        ]),
      );
    });

    test('with null localizations returns empty descriptions', () {
      final builtIns = SlashCommandCatalog.builtIns(null);
      for (final cmd in builtIns) {
        expect(cmd.description, isEmpty);
      }
    });

    test('with localizations returns localized descriptions', () {
      final builtIns = SlashCommandCatalog.builtIns(FakeLocalizations());
      final skills = builtIns.firstWhere((c) => c.name == '/skills');
      expect(skills.description, 'Show skills');
      final thinking = builtIns.firstWhere((c) => c.name == '/thinking');
      expect(thinking.description, 'Thinking');
    });

    test('built-ins have no template/payload', () {
      final builtIns = SlashCommandCatalog.builtIns(null);
      for (final cmd in builtIns) {
        expect(cmd.template, isNull);
        expect(cmd.hints, isEmpty);
      }
    });
  });

  group('SlashCommandCatalog.fromCommandInfo', () {
    test('maps CommandInfo to SlashCommand', () {
      const info = CommandInfo(
        name: 'review',
        template: 'Review \$1',
        description: 'Review code',
        agent: 'reviewer',
        model: 'gpt-4',
        variant: 'fast',
        subtask: true,
      );
      final cmd = SlashCommandCatalog.fromCommandInfo(info);
      expect(cmd.name, '/review');
      expect(cmd.description, 'Review code');
      expect(cmd.template, 'Review \$1');
      expect(cmd.agent, 'reviewer');
      expect(cmd.model, 'gpt-4');
      expect(cmd.variant, 'fast');
      expect(cmd.subtask, isTrue);
      expect(cmd.hints, [r'$1']);
    });

    test('uses empty description when null', () {
      const info = CommandInfo(name: 'test', template: 'do \$1');
      final cmd = SlashCommandCatalog.fromCommandInfo(info);
      expect(cmd.description, isEmpty);
    });

    test('generates hints from template', () {
      const info = CommandInfo(
        name: 'test',
        template: 'hello \$1 and \$ARGUMENTS',
      );
      final cmd = SlashCommandCatalog.fromCommandInfo(info);
      expect(cmd.hints, [r'$1', r'$ARGUMENTS']);
    });
  });

  group('SlashCommandCatalog.filter', () {
    final commands = [
      const SlashCommand('/skills', 'Show skills'),
      const SlashCommand('/new', 'Start new chat'),
      const SlashCommand('/thinking', 'Toggle reasoning visibility'),
      const SlashCommand('/review', 'Review code'),
    ];

    test('empty query returns all', () {
      expect(
        SlashCommandCatalog.filter(commands, ''),
        hasLength(commands.length),
      );
      expect(
        SlashCommandCatalog.filter(commands, '   '),
        hasLength(commands.length),
      );
    });

    test('filters by name contains case-insensitive', () {
      final result = SlashCommandCatalog.filter(commands, 'skill');
      expect(result, hasLength(1));
      expect(result.first.name, '/skills');
    });

    test('filters by description contains case-insensitive', () {
      final result = SlashCommandCatalog.filter(commands, 'reasoning');
      expect(result, hasLength(1));
      expect(result.first.name, '/thinking');
    });

    test('query with slash still matches', () {
      final result = SlashCommandCatalog.filter(commands, '/new');
      expect(result, hasLength(1));
      expect(result.first.name, '/new');
    });

    test('no matches returns empty', () {
      final result = SlashCommandCatalog.filter(commands, 'nonexistent');
      expect(result, isEmpty);
    });

    test('partial match finds multiple', () {
      final result = SlashCommandCatalog.filter(commands, 're');
      // matches /review (name) and /thinking (reasoning)
      expect(result.length, greaterThanOrEqualTo(2));
    });
  });
}
