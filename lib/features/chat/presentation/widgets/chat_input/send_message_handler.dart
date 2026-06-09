import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/chat/domain/services/speech_to_text_service.dart';
import 'package:chatorai/features/chat/presentation/widgets/model_settings_sheet.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/providers.dart';

mixin SendMessageHandler<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  TextEditingController get textController;
  SpeechToTextService? get speechService;
  bool Function(String)? get checkModelSupportsImages;

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
    String? delegateAgentId;
    final agentMatch = RegExp(r'^@(\S+)\s*').firstMatch(text);
    if (agentMatch != null) {
      final agentId = agentMatch.group(1);
      if (AgentRegistry().get(agentId!) != null) {
        delegateAgentId = agentId;
        text = text.substring(agentMatch.end);
      }
    }
    final messageData = MessageData(
      text: text,
      delegateAgentId: delegateAgentId,
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
    final localizations = AppLocalizations.of(context);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const ModelSettingsSheet(),
          );
        },
      ),
    );
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
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : (agent.color != null
                            ? Color(
                                int.parse(
                                  agent.color!.replaceFirst('#', '0xFF'),
                                ),
                              )
                            : Theme.of(context).colorScheme.outline),
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(
                agent.name,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
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
