import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/command_providers.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/features/settings/widgets/model_settings_sheet.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin SendMessageHandler<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  TextEditingController get textController;
  SpeechToTextService? get speechService;
  bool Function(String)? get checkModelSupportsImages;
  VoidCallback? get onOpenModelSettings;
  Future<void> Function()? get onCompact;

  /// Override to transform/resolve text before sending.
  /// Return null to cancel normal send (e.g. skill with no args).
  /// Return a [ResolvedText] to continue with modified text and optional delegate.
  /// Expands a file-defined command invocation (`/name args`) into its
  /// template payload. Returns null when [name] is not a known custom
  /// command, letting the caller keep the text untouched.
  Future<ResolvedText?> _resolveCustomCommand(
    String name,
    String arguments,
  ) async {
    final command = await (await ref.read(
      commandServiceProvider.future,
    )).getByName(name);
    if (command == null) return null;

    final targetId = command.agent;
    final explicitTarget = (targetId == null || targetId.isEmpty)
        ? null
        : AgentRegistry().get(targetId);
    // Reference semantics: an undeclared agent resolves to the session's
    // default agent, which then participates in the subtask rule.
    final target = resolveCommandTarget(
      explicitTarget,
      ref.read(currentAgentProvider),
    );

    if (isSubtaskRule(target, command.subtask)) {
      // Delegated execution: the expanded template goes to the child session;
      // the parent keeps only the original invocation.
      return ResolvedText(
        text: expandCommandTemplate(command.template, arguments),
        agentMention: target.id,
        runAsSubtask: true,
        taskTitle: command.description ?? '/$name',
        invocation: arguments.isEmpty
            ? '/${command.name}'
            : '/${command.name} $arguments',
      );
    }

    // Inline execution: model chain is the command's own model first, then
    // the explicitly declared agent's model; applied only when it exists.
    final wantedModel = command.model ?? explicitTarget?.model;
    if (wantedModel != null && wantedModel.isNotEmpty) {
      final ids = ref
          .read(modelProvider)
          .availableModels
          .map((m) => m.id)
          .toSet();
      final matched = matchModelId(ids, wantedModel);
      if (matched != null) {
        await ref.read(modelProvider.notifier).setSelectedModel(matched);
      } else {
        LogTags.chat.logDebug('Command model "$wantedModel" unavailable');
      }
    }

    return ResolvedText(
      text: expandCommandTemplate(command.template, arguments),
    );
  }

  Future<ResolvedText?> resolveText(String text) async {
    String? agentMention;
    final agentMatch = RegExp(r'^@(\S+)\s*').firstMatch(text);
    if (agentMatch != null) {
      final agentId = agentMatch.group(1);
      if (agentId != null) {
        final agent = AgentRegistry().get(agentId);
        if (agent != null) {
          // For subagents: mark for task tool delegation (keep text as-is for chat display)
          if (agent.mode == AgentMode.subagent) {
            agentMention = agentId;
            // Do NOT remove @mention - it stays in the message
          }
          // For primary agents: ignore @mention (they are set via agent switcher)
        }
      }
    }

    final commandMatch = RegExp(
      r'^(/.+?)(?:\s+(.*))?$',
      dotAll: true,
    ).firstMatch(text);
    if (commandMatch != null) {
      final resolved = await _resolveCustomCommand(
        commandMatch.group(1)!.substring(1),
        commandMatch.group(2) ?? '',
      );
      if (resolved != null) return resolved;
    }

    return ResolvedText(text: text, agentMention: agentMention);
  }

  Future<void> performSend({
    required void Function(MessageData) onSendMessage,
    required void Function(bool) onToggleStreaming,
    required void Function() onClearAttachedFile,
  }) async {
    FocusScope.of(context).unfocus();
    final localizations = AppLocalizations.of(context)!;
    if (textController.text.trim().isEmpty &&
        ref.read(chatInputProvider).attachedFilePath == null) {
      return;
    }
    if (ref.read(chatInputProvider).attachedFilePath != null &&
        ref.read(chatInputProvider).attachedBase64Data != null) {
      if (checkModelSupportsImages != null) {
        final modelId = ref.read(modelProvider).selectedModelId;
        final supportsImages = checkModelSupportsImages!(modelId);
        if (!supportsImages) {
          if (mounted) {
            SnackbarUtils.showErrorSnackBar(
              context: context,
              message: localizations.modelDoesNotSupportFiles(modelId),
              icon: Icons.image_not_supported,
              duration: const Duration(seconds: 5),
            );
          }
          ref.read(chatInputProvider.notifier).setIsSending(false);
          return;
        }
      }
    }
    ref.read(chatInputProvider.notifier).setIsSending(true);
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
      await speechService?.stopListening();
    }
    var text = textController.text.trim();

    if (text == '/new' || text.startsWith('/new ')) {
      textController.clear();
      onClearAttachedFile();
      ref.read(chatInputProvider.notifier).setIsSending(false);
      return;
    }

    if (text == '/compact' || text.startsWith('/compact ')) {
      await onCompact?.call();
      textController.clear();
      onClearAttachedFile();
      ref.read(chatInputProvider.notifier).setIsSending(false);
      return;
    }

    final resolved = await resolveText(text);
    if (resolved == null) {
      // resolveText handled the send (e.g. skill no-args insert)
      textController.clear();
      onClearAttachedFile();
      ref.read(chatInputProvider.notifier).setIsSending(false);
      return;
    }

    // Subtask commands keep the original invocation visible in the parent
    // session; the expanded template travels in taskPrompt.
    text = resolved.runAsSubtask
        ? (resolved.invocation ?? text)
        : resolved.text;
    final chatInput = ref.read(chatInputProvider);
    final messageData = MessageData(
      text: text,
      agentMention: resolved.agentMention,
      runAsSubtask: resolved.runAsSubtask,
      taskPrompt: resolved.runAsSubtask ? resolved.text : null,
      taskTitle: resolved.taskTitle,
      imagePath: chatInput.attachedFilePath,
      imageType: chatInput.attachedImageType,
      imageName: chatInput.attachedFileName,
      base64Data: chatInput.attachedBase64Data,
      // attachedImageType == null && attachedFilePath != null → document
      // attachedImageType != null                         → image
      attachedDocPath: chatInput.attachedImageType == null
          ? chatInput.attachedFilePath
          : null,
    );
    onSendMessage(messageData);
    onToggleStreaming(true);
    textController.clear();
    onClearAttachedFile();
    ref.read(chatInputProvider.notifier).setIsSending(false);
  }

  Future<void> handleModelSettings() async {
    final modelState = ref.read(modelProvider);
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context)!;
    if (modelState.selectedModelId.isEmpty) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.noModelSelected,
        icon: Icons.error,
      );
      return;
    }
    if (settingsState.activeSettings?.modelId != modelState.selectedModelId) {
      await settingsNotifier.setActiveModel(modelState.selectedModelId);
    }
    if (!mounted) return;
    if (onOpenModelSettings != null) {
      onOpenModelSettings!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => const ModelSettingsSheet(),
        ),
      );
    }
  }

  void showAgentSwitcher(BuildContext context, GlobalKey agentKey) {
    final currentAgent = ref.read(currentAgentProvider);
    final primaryAgents = AgentRegistry().getPrimaryAgents();
    if (primaryAgents.isEmpty) return;

    // Позиционируем меню относительно кнопки агента, если она доступна,
    // иначе — относительно переданного context (всегда валиден).
    RelativeRect position;
    final RenderBox? box =
        agentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 120,
        offset.dx + size.width,
        offset.dy,
      );
    } else {
      final render = context.findRenderObject();
      if (render is! RenderBox) return;
      final offset = render.localToGlobal(Offset.zero);
      final size = render.size;
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 120,
        offset.dx + size.width,
        offset.dy,
      );
    }

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      items: primaryAgents.map((agent) {
        final isActive = agent.id == currentAgent.id;
        return PopupMenuItem<String>(
          value: agent.id,
          enabled: !isActive,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(
                agent.name,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive) const Spacer(),
            ],
          ),
        );
      }).toList(),
    ).then((agentId) {
      if (agentId != null) {
        final agent = AgentRegistry().get(agentId);
        if (agent != null) {
          ref.read(currentAgentProvider.notifier).setAgent(agent);
        }
      }
    });
  }
}

/// Result of [SendMessageHandler.resolveText].
class ResolvedText {
  final String text;
  final String? agentMention;

  /// True when the resolved text must execute as a delegated subagent task
  /// instead of a normal parent-session message.
  final bool runAsSubtask;

  /// Short card title for the delegated task (command description).
  final String? taskTitle;

  /// Original `/name args` invocation shown in the parent session when the
  /// command runs as a subtask.
  final String? invocation;

  const ResolvedText({
    required this.text,
    this.agentMention,
    this.runAsSubtask = false,
    this.taskTitle,
    this.invocation,
  });
}
