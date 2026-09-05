import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/slash_command.dart';

/// Abstraction over localized strings for built-in slash commands.
///
/// Implemented by `AppLocalizations` in the presentation layer and by
/// TUI localizations. Keeping this interface in `core` avoids a Flutter
/// dependency while still allowing localized descriptions.
abstract class SlashCommandLocalizations {
  String get slashCommandSkills;
  String get slashCommandNew;
  String get slashCommandClear;
  String get slashCommandCompact;
  String get slashCommandHelp;
  String get slashCommandUndo;
  String get slashCommandRedo;
  String get slashCommandSessions;
  String get slashCommandModels;
  String get slashCommandTheme;
  String get slashCommandThinking;
}

/// Single source of truth for slash-command definitions and filtering.
///
/// Shared by GUI (Flutter) and TUI (Nocterm) interfaces.
class SlashCommandCatalog {
  const SlashCommandCatalog._();

  static const List<String> _builtinNames = [
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
  ];

  static String _localizedDescription(
    SlashCommandLocalizations? loc,
    String name,
  ) {
    if (loc == null) return '';
    switch (name) {
      case '/skills':
        return loc.slashCommandSkills;
      case '/new':
        return loc.slashCommandNew;
      case '/clear':
        return loc.slashCommandClear;
      case '/compact':
        return loc.slashCommandCompact;
      case '/help':
        return loc.slashCommandHelp;
      case '/undo':
        return loc.slashCommandUndo;
      case '/redo':
        return loc.slashCommandRedo;
      case '/sessions':
        return loc.slashCommandSessions;
      case '/models':
        return loc.slashCommandModels;
      case '/theme':
        return loc.slashCommandTheme;
      case '/thinking':
        return loc.slashCommandThinking;
      default:
        return '';
    }
  }

  /// Returns the 11 built-in commands with localized descriptions.
  static List<SlashCommand> builtIns(SlashCommandLocalizations? localizations) {
    return _builtinNames
        .map(
          (name) =>
              SlashCommand(name, _localizedDescription(localizations, name)),
        )
        .toList(growable: false);
  }

  /// Maps a file-defined [CommandInfo] to a [SlashCommand].
  static SlashCommand fromCommandInfo(CommandInfo info) {
    return SlashCommand(
      '/${info.name}',
      info.description ?? '',
      template: info.template,
      agent: info.agent,
      model: info.model,
      variant: info.variant,
      subtask: info.subtask,
      hints: commandHints(info.template),
    );
  }

  /// Filters [commands] by whether [query] appears in name or description.
  ///
  /// Case-insensitive, trims whitespace. Empty query returns all commands.
  /// Matches both `/skill` and `skill` style queries against `/skills`.
  static List<SlashCommand> filter(List<SlashCommand> commands, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List<SlashCommand>.from(commands);
    final lower = trimmed.toLowerCase();
    return commands
        .where(
          (c) =>
              c.name.toLowerCase().contains(lower) ||
              c.description.toLowerCase().contains(lower),
        )
        .toList(growable: false);
  }
}
