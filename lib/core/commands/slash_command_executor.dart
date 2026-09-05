import 'package:chatorai/core/commands/slash_command.dart';

/// Context callbacks for executing built-in slash commands.
///
/// Each callback is optional so TUI and GUI can provide only what they need.
/// The executor invokes these without knowing whether it runs in Flutter or
/// Nocterm — the caller wires the correct side-effects.
class SlashCommandExecutorContext {
  final Future<void> Function()? onCompact;
  final Future<void> Function()? onCreateNewChat;
  final void Function(bool newValue)? onSetExpandReasoning;
  final bool? expandReasoningCurrent;
  final void Function()? clearInput;

  const SlashCommandExecutorContext({
    this.onCompact,
    this.onCreateNewChat,
    this.onSetExpandReasoning,
    this.expandReasoningCurrent,
    this.clearInput,
  });
}

/// Result of executing a slash command via [SlashCommandExecutor].
class SlashCommandExecutionResult {
  final bool handled;

  const SlashCommandExecutionResult({required this.handled});

  static const handledResult = SlashCommandExecutionResult(handled: true);
  static const notHandled = SlashCommandExecutionResult(handled: false);
}

/// Executes built-in slash commands with shared business logic for all
/// interfaces (GUI and TUI). Other commands (e.g. `/help`) are not handled
/// here and should be treated as plain text insertion by the caller.
class SlashCommandExecutor {
  const SlashCommandExecutor._();

  static Future<SlashCommandExecutionResult> execute(
    SlashCommand command,
    SlashCommandExecutorContext ctx,
  ) async {
    switch (command.name) {
      case '/compact':
        await ctx.onCompact?.call();
        ctx.clearInput?.call();
        return SlashCommandExecutionResult.handledResult;
      case '/new':
        ctx.clearInput?.call();
        await ctx.onCreateNewChat?.call();
        return SlashCommandExecutionResult.handledResult;
      case '/thinking':
        final newValue = !(ctx.expandReasoningCurrent ?? false);
        ctx.onSetExpandReasoning?.call(newValue);
        ctx.clearInput?.call();
        return SlashCommandExecutionResult.handledResult;
      default:
        return SlashCommandExecutionResult.notHandled;
    }
  }
}
