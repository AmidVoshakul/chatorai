import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A user-defined slash command parsed from a markdown file.
class CommandInfo {
  final String name;
  final String template;
  final String? description;
  final String? agent;
  final String? model;
  final String? variant;
  final bool? subtask;

  const CommandInfo({
    required this.name,
    required this.template,
    this.description,
    this.agent,
    this.model,
    this.variant,
    this.subtask,
  });
}

/// Strips the known `command/` / `commands/` prefix from an entry path
/// relative to the config root, removes the extension, and preserves nested
/// structure: `commands/fe/review.md` -> `fe/review`. Paths without a known
/// prefix fall back to their basename.
String commandEntryName(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  var candidate = normalized;
  for (final prefix in const ['commands/', 'command/']) {
    if (candidate.startsWith(prefix)) {
      candidate = candidate.substring(prefix.length);
      break;
    }
  }
  if (candidate == normalized) {
    candidate = p.basename(candidate);
  }
  final ext = p.extension(candidate);
  return ext.isNotEmpty
      ? candidate.substring(0, candidate.length - ext.length)
      : candidate;
}

/// Extracts argument placeholders (`$1`, `$2`, ..., `$ARGUMENTS`) declared by
/// a command template, for display in the command palette.
List<String> commandHints(String template) {
  final hints = <String>[];
  final seen = <String>{};
  for (final match in RegExp(r'\$\d+').allMatches(template)) {
    final hint = match.group(0)!;
    if (seen.add(hint)) hints.add(hint);
  }
  hints.sort();
  if (template.contains(r'$ARGUMENTS')) hints.add(r'$ARGUMENTS');
  return hints;
}

/// Builds the model-only continuation note injected into the parent context
/// after a delegated subtask finishes. Never written to visible history.
String buildSubtaskResultNote({
  required String agentName,
  required String taskTitle,
  required String output,
}) {
  return '[SUBTASK RESULT]\n'
      'agent: $agentName\n'
      'task: $taskTitle\n'
      '--- begin output ---\n'
      '$output\n'
      '--- end output ---\n'
      'Continue answering the user in the parent conversation using this '
      'result.';
}

/// Resolves the agent executing a command: the declared `agent` when present,
/// otherwise the session's default (active) agent.
AgentDefinition resolveCommandTarget(
  AgentDefinition? explicitTarget,
  AgentDefinition fallbackTarget,
) => explicitTarget ?? fallbackTarget;

/// Whether a command invocation must execute as a delegated subagent task:
/// subagents take the task path by default, and `subtask: true` forces it
/// for any resolved target.
bool isSubtaskRule(AgentDefinition target, bool? subtaskFlag) =>
    (target.mode == AgentMode.subagent && subtaskFlag != false) ||
    subtaskFlag == true;

/// Finds [wanted] among available model ids (`provider/model` format).
/// Matches an exact id first, then a unique `provider/` suffix so bare names
/// like `gpt-4o` resolve to their only provider entry. Ambiguous or missing
/// names return null.
String? matchModelId(Set<String> availableIds, String wanted) {
  final trimmed = wanted.trim();
  if (trimmed.isEmpty) return null;
  if (availableIds.contains(trimmed)) return trimmed;
  final suffixMatches = availableIds
      .where((id) => id.endsWith('/$trimmed'))
      .toList(growable: false);
  return suffixMatches.length == 1 ? suffixMatches.single : null;
}

/// Substitutes argument placeholders in a command template.
///
/// - `$N` maps to the N-th whitespace-separated argument; the highest N
///   present consumes all remaining arguments joined by spaces.
/// - `$ARGUMENTS` expands to the raw, unsplit argument string.
/// - A template without any placeholder gets the trimmed arguments appended
///   as a new paragraph.
String expandCommandTemplate(String template, String arguments) {
  final args = arguments
      .trim()
      .split(RegExp(r'\s+'))
      .where((a) => a.isNotEmpty)
      .toList();
  final placeholders = RegExp(r'\$(\d+)').allMatches(template).toList();

  var result = template;
  if (placeholders.isNotEmpty) {
    var last = 0;
    for (final match in placeholders) {
      final value = int.parse(match.group(1)!);
      if (value > last) last = value;
    }
    result = template.replaceAllMapped(RegExp(r'\$(\d+)'), (match) {
      final position = int.parse(match.group(1)!);
      // Positions are 1-based: `$0` references no argument, so it contributes
      // an empty string instead of indexing before the start of [args].
      if (position < 1) return '';
      final argIndex = position - 1;
      if (argIndex >= args.length) return '';
      if (position == last) return args.skip(argIndex).join(' ');
      return args[argIndex];
    });
  }

  if (template.contains(r'$ARGUMENTS')) {
    result = result.replaceAll(r'$ARGUMENTS', arguments);
  } else if (placeholders.isEmpty && arguments.trim().isNotEmpty) {
    result = '$result\n\n${arguments.trim()}';
  }
  return result.trim();
}

/// Parses markdown files with YAML frontmatter into [CommandInfo].
class CommandParser {
  const CommandParser._();

  /// [entryPath] is the path of the file relative to its config root
  /// (e.g. `commands/fe/review.md`); it determines the command name.
  static CommandInfo parse(String entryPath, String content) {
    final lines = content.split('\n');

    int? fmStart;
    int? fmEnd;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim() != '---') continue;
      if (fmStart == null) {
        fmStart = i;
      } else {
        fmEnd = i;
        break;
      }
    }
    if (fmStart == null || fmEnd == null) {
      throw FormatException('Missing frontmatter delimiters (---)', entryPath);
    }

    final frontMatter = lines.sublist(fmStart + 1, fmEnd).join('\n');
    final template = lines.sublist(fmEnd + 1).join('\n').trim();

    YamlMap? yaml;
    try {
      yaml = loadYaml(frontMatter) as YamlMap?;
    } catch (e) {
      throw FormatException('YAML parse error: $e', entryPath);
    }

    if (template.isEmpty) {
      throw FormatException('Empty command template', entryPath);
    }

    final name = commandEntryName(entryPath);
    // A usable slash command must start with a word character and may nest
    // through directories (`fe/review`). Dotfiles like `.md` or empty
    // segments yield unusable names and are rejected here.
    if (!RegExp(r'^\w[\w\-./]*$').hasMatch(name)) {
      throw FormatException('Invalid command name: "$name"', entryPath);
    }

    String? field(String key) => yaml?[key]?.toString();

    final subtaskValue = yaml?['subtask'];
    final subtask = subtaskValue is bool ? subtaskValue : null;

    return CommandInfo(
      name: name,
      template: template,
      description: field('description'),
      agent: field('agent'),
      model: field('model'),
      variant: field('variant'),
      subtask: subtask,
    );
  }
}
