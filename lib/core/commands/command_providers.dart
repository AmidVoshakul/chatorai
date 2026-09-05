import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/command_service.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/shared/utils/chatorai_roots.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped whenever a watched command file changes on disk, so dependents
/// re-read the merged command list.
class CommandsVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final commandsVersionProvider = NotifierProvider<CommandsVersion, int>(
  CommandsVersion.new,
);

/// Config roots scanned for custom commands, ordered global-first; the
/// project chain follows (topmost ancestor first) so the directory closest
/// to the working directory wins name conflicts.
List<String> commandRoots({String? start}) {
  final roots = <String>[];
  try {
    roots.add(XdgPaths.configHome);
  } on UnsupportedError catch (_) {
    // Mobile before the platform path cache is initialized: global commands
    // stay unavailable and only project files are loaded.
  }
  roots.addAll(projectChatoraiRoots(start: start));
  return roots;
}

/// Commands declared in the `command` section of chatorai.json. Entries with
/// an empty template are skipped (logged), matching the lenient file policy.
Map<String, CommandInfo> commandsFromConfig(ChatOrAIConfig? config) {
  final section = config?.command;
  if (section == null) return const {};
  final result = <String, CommandInfo>{};
  for (final entry in section.commands.entries) {
    if (entry.value.template.trim().isEmpty) {
      LogTags.chat.logWarning(
        'Skipping config command "${entry.key}": empty template',
      );
      continue;
    }
    result[entry.key] = CommandInfo(
      name: entry.key,
      template: entry.value.template,
      description: entry.value.description,
      agent: entry.value.agent,
      model: entry.value.model,
      variant: entry.value.variant,
      subtask: entry.value.subtask,
    );
  }
  return result;
}

final commandServiceProvider = FutureProvider<CommandService>((ref) async {
  final config = await ref.watch(configProvider.future);
  final service = CommandService(
    roots: commandRoots(),
    fromJson: commandsFromConfig(config),
    onChanged: () {
      try {
        ref.read(commandsVersionProvider.notifier).bump();
      } catch (_) {
        // Container already disposed; nothing left to notify.
      }
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Custom commands merged across JSON config, global and project scopes.
/// Re-evaluated automatically after any watched file change or config reload.
final customCommandsProvider = FutureProvider<List<CommandInfo>>((ref) async {
  ref.watch(commandsVersionProvider);
  return ref.watch(commandServiceProvider.future).then((s) => s.listAll());
});
