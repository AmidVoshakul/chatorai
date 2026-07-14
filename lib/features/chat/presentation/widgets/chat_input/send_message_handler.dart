import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/features/settings/widgets/model_settings_sheet.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin SendMessageHandler<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  TextEditingController get textController;
  SpeechToTextService? get speechService;
  bool Function(String)? get checkModelSupportsImages;
  VoidCallback? get onOpenModelSettings;

  /// Override to transform/resolve text before sending.
  /// Return null to cancel normal send (e.g. skill with no args).
  /// Return a [ResolvedText] to continue with modified text and optional delegate.
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
    return ResolvedText(text: text, agentMention: agentMention);
  }

  Future<void> performSend({
    required void Function(MessageData) onSendMessage,
    required void Function(bool) onToggleStreaming,
    required void Function() onClearAttachedFile,
  }) async {
    FocusScope.of(context).unfocus();
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
              message:
                  'Модель $modelId не поддерживает файлы. Удалите файл или выберите другую модель.',
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

    final resolved = await resolveText(text);
    if (resolved == null) {
      // resolveText handled the send (e.g. skill no-args insert)
      textController.clear();
      onClearAttachedFile();
      ref.read(chatInputProvider.notifier).setIsSending(false);
      return;
    }

    text = resolved.text;
    final messageData = MessageData(
      text: text,
      agentMention: resolved.agentMention,
      imagePath: ref.read(chatInputProvider).attachedFilePath,
      imageType: ref.read(chatInputProvider).attachedImageType,
      base64Data: ref.read(chatInputProvider).attachedBase64Data,
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
    final RenderBox? box =
        agentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 120,
        offset.dx + size.width,
        offset.dy,
      ),
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
      if (agentId != null && mounted) {
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

  const ResolvedText({required this.text, this.agentMention});
}
