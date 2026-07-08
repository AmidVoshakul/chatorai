import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/features/chat/data/providers/chat_input_provider.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/input_widget_builders.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputLayoutBuilder {
  static Widget buildContainer({
    required bool isMobile,
    required ThemeData theme,
    required Widget child,
  }) {
    return Container(
      padding: isMobile
          ? const EdgeInsets.only(top: ChatoraiSpacing.lg)
          : const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: BoxDecoration(
        color: isMobile
            ? (theme.brightness == Brightness.dark
                  ? ChatoraiColors.inputContainerDark
                  : ChatoraiColors.inputContainerLight)
            : Colors.transparent,
        border: isMobile
            ? Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? ChatoraiColors.inputContainerBorderDark
                      : ChatoraiColors.inputContainerBorderLight,
                  width: ChatoraiBorderWidth.thinBold,
                ),
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? ChatoraiColors.navBarBorderDark
                      : ChatoraiColors.navBarBorderLight,
                  width: ChatoraiBorderWidth.thinBold,
                ),
              )
            : null,
        boxShadow: isMobile
            ? [
                BoxShadow(
                  color: ChatoraiColors.black30,
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: ChatoraiColors.black20,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: ChatoraiColors.black05,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
        borderRadius: isMobile
            ? const BorderRadius.only(
                topLeft: Radius.circular(ChatoraiBorderRadius.xl),
                topRight: Radius.circular(ChatoraiBorderRadius.xl),
              )
            : BorderRadius.zero,
      ),
      child: child,
    );
  }

  static Widget buildMobileLayout({
    required BuildContext context,
    required ThemeData theme,
    required ChatInputState chatInputState,
    required Widget textField,
    required bool isMobile,
    required bool hasText,
    required bool hasAttachment,
    required double buttonSize,
    required double iconSize,
    required double sidePadding,
    required double bottomPadding,
    required VoidCallback onClearAttachedFile,
    required VoidCallback onPlusMenu,
    required VoidCallback onModelSettings,
    required VoidCallback onAgentSwitcher,
    required VoidCallback onMicrophoneAction,
    required VoidCallback onSend,
    required VoidCallback? onStopStreaming,
    required VoidCallback? onLongPressMic,
    required WidgetRef ref,
    required GlobalKey plusKey,
    required GlobalKey settingsKey,
    required GlobalKey agentKey,
    required bool isStreaming,
    required AgentDefinition currentAgent,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chatInputState.attachedFilePath != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
            child: InputWidgetBuilders.buildAttachedFilePreview(
              state: chatInputState,
              isMobile: isMobile,
              onRemove: onClearAttachedFile,
              localizations: localizations,
            ),
          ),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 48,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? ChatoraiColors.inputContainerDark
                  : ChatoraiColors.inputContainerLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ChatoraiBorderRadius.xl),
                topRight: Radius.circular(ChatoraiBorderRadius.xl),
              ),
            ),
            child: textField,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            0,
            sidePadding,
            bottomPadding,
          ),
          child: buildButtonRow(
            context: context,
            theme: theme,
            chatInputState: chatInputState,
            hasText: hasText,
            hasAttachment: hasAttachment,
            buttonSize: buttonSize,
            iconSize: iconSize,
            onPlusMenu: onPlusMenu,
            onModelSettings: onModelSettings,
            onAgentSwitcher: onAgentSwitcher,
            onMicrophoneAction: onMicrophoneAction,
            onSend: onSend,
            onStopStreaming: onStopStreaming,
            onLongPressMic: onLongPressMic,
            ref: ref,
            plusKey: plusKey,
            settingsKey: settingsKey,
            agentKey: agentKey,
            isStreaming: isStreaming,
            currentAgent: currentAgent,
          ),
        ),
      ],
    );
  }

  static Widget buildDesktopLayout({
    required BuildContext context,
    required ThemeData theme,
    required ChatInputState chatInputState,
    required Widget textField,
    required bool isMobile,
    required bool hasText,
    required bool hasAttachment,
    required double buttonSize,
    required double iconSize,
    required VoidCallback onClearAttachedFile,
    required VoidCallback onPlusMenu,
    required VoidCallback onModelSettings,
    required VoidCallback onAgentSwitcher,
    required VoidCallback onMicrophoneAction,
    required VoidCallback onSend,
    required VoidCallback? onStopStreaming,
    required VoidCallback? onLongPressMic,
    required WidgetRef ref,
    required GlobalKey plusKey,
    required GlobalKey settingsKey,
    required GlobalKey agentKey,
    required bool isStreaming,
    required AgentDefinition currentAgent,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InputWidgetBuilders.buildActionButton(
          key: plusKey,
          buttonSize: buttonSize,
          bgColor: theme.brightness == Brightness.dark
              ? ChatoraiColors.inputContainerDark
              : ChatoraiColors.inputContainerLight,
          onTap: onPlusMenu,
          tooltip: localizations.addFileTooltip,
          child: Icon(Icons.add, color: theme.iconTheme.color),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        InputWidgetBuilders.buildActionButton(
          key: settingsKey,
          buttonSize: buttonSize,
          bgColor: theme.brightness == Brightness.dark
              ? ChatoraiColors.inputContainerDark
              : ChatoraiColors.inputContainerLight,
          onTap: onModelSettings,
          tooltip: localizations.modelSettingsTooltip,
          child: Icon(
            Icons.settings_input_component_outlined,
            color: theme.iconTheme.color,
          ),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        InputWidgetBuilders.buildAgentButton(
          key: agentKey,
          theme: theme,
          currentAgent: currentAgent,
          onTap: onAgentSwitcher,
          tooltip: localizations.switchAgentTooltip,
        ),
        const SizedBox(width: ChatoraiSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chatInputState.attachedFilePath != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.xs,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: InputWidgetBuilders.buildAttachedFilePreview(
                      state: chatInputState,
                      isMobile: isMobile,
                      onRemove: onClearAttachedFile,
                      localizations: localizations,
                    ),
                  ),
                ),
                const SizedBox(height: ChatoraiSpacing.xs),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? ChatoraiColors.inputContainerDark
                        : ChatoraiColors.inputContainerLight,
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderRadius.md,
                    ),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? ChatoraiColors.inputContainerBorderDark
                          : ChatoraiColors.inputContainerBorderLight,
                      width: ChatoraiBorderWidth.thinBold,
                    ),
                  ),
                  child: textField,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: ChatoraiSpacing.md),
        _buildActionOrStopButton(
          context: context,
          theme: theme,
          chatInputState: chatInputState,
          hasText: hasText,
          hasAttachment: hasAttachment,
          buttonSize: buttonSize,
          iconSize: iconSize,
          onMicrophoneAction: onMicrophoneAction,
          onSend: onSend,
          onStopStreaming: onStopStreaming,
          onLongPressMic: onLongPressMic,
          ref: ref,
          isStreaming: isStreaming,
        ),
      ],
    );
  }

  static Widget buildButtonRow({
    required BuildContext context,
    required ThemeData theme,
    required ChatInputState chatInputState,
    required bool hasText,
    required bool hasAttachment,
    required double buttonSize,
    required double iconSize,
    required VoidCallback onPlusMenu,
    required VoidCallback onModelSettings,
    required VoidCallback onAgentSwitcher,
    required VoidCallback onMicrophoneAction,
    required VoidCallback onSend,
    required VoidCallback? onStopStreaming,
    required VoidCallback? onLongPressMic,
    required WidgetRef ref,
    required GlobalKey plusKey,
    required GlobalKey settingsKey,
    required GlobalKey agentKey,
    required bool isStreaming,
    required AgentDefinition currentAgent,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        InputWidgetBuilders.buildActionButton(
          key: plusKey,
          buttonSize: buttonSize,
          gradient: chatInputState.plusActive
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          bgColor: chatInputState.plusActive
              ? null
              : (theme.brightness == Brightness.dark
                    ? ChatoraiColors.inputContainerDark
                    : ChatoraiColors.inputContainerLight),
          onTap: onPlusMenu,
          tooltip: localizations.addFileTooltip,
          child: Icon(
            Icons.add,
            size: iconSize,
            color: chatInputState.plusActive
                ? ChatoraiColors.pureWhite
                : theme.iconTheme.color,
          ),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        InputWidgetBuilders.buildActionButton(
          key: settingsKey,
          buttonSize: buttonSize,
          bgColor: theme.brightness == Brightness.dark
              ? ChatoraiColors.inputContainerDark
              : ChatoraiColors.inputContainerLight,
          onTap: onModelSettings,
          tooltip: localizations.modelSettingsTooltip,
          child: Icon(
            Icons.settings_input_component_outlined,
            size: iconSize,
            color: theme.iconTheme.color,
          ),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        InputWidgetBuilders.buildAgentButton(
          key: agentKey,
          theme: theme,
          currentAgent: currentAgent,
          onTap: onAgentSwitcher,
          tooltip: localizations.switchAgentTooltip,
        ),
        const Spacer(),
        _buildActionOrStopButton(
          context: context,
          theme: theme,
          chatInputState: chatInputState,
          hasText: hasText,
          hasAttachment: hasAttachment,
          buttonSize: buttonSize,
          iconSize: iconSize,
          onMicrophoneAction: onMicrophoneAction,
          onSend: onSend,
          onStopStreaming: onStopStreaming,
          onLongPressMic: onLongPressMic,
          ref: ref,
          isStreaming: isStreaming,
        ),
      ],
    );
  }

  static Widget _buildActionOrStopButton({
    required BuildContext context,
    required ThemeData theme,
    required ChatInputState chatInputState,
    required bool hasText,
    required bool hasAttachment,
    required double buttonSize,
    required double iconSize,
    required VoidCallback onMicrophoneAction,
    required VoidCallback onSend,
    required VoidCallback? onStopStreaming,
    required VoidCallback? onLongPressMic,
    required WidgetRef ref,
    required bool isStreaming,
  }) {
    if (isStreaming) {
      return InputWidgetBuilders.buildStopButton(
        context,
        ref,
        onStopStreaming: onStopStreaming,
      );
    }
    final isListening =
        chatInputState.speechUiState == SpeechUiState.listening ||
        chatInputState.speechUiState == SpeechUiState.preparing;
    final isIdle = chatInputState.speechUiState == SpeechUiState.idle;
    final showGradient = (hasText || hasAttachment) || !isIdle;

    return InputWidgetBuilders.buildActionButton(
      buttonSize: buttonSize,
      gradient: showGradient
          ? LinearGradient(
              colors: [
                isListening ? ChatoraiColors.error : theme.colorScheme.primary,
                isListening
                    ? ChatoraiColors.error.withValues(alpha: 0.8)
                    : theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            )
          : null,
      bgColor: showGradient
          ? null
          : (theme.brightness == Brightness.dark
                ? ChatoraiColors.inputContainerDark
                : ChatoraiColors.inputContainerLight),
      onTap: isListening
          ? onMicrophoneAction
          : (hasText || hasAttachment ? onSend : onMicrophoneAction),
      onLongPress: isListening ? null : onLongPressMic,
      child: Icon(
        InputWidgetBuilders.getActionIcon(
          isSending: chatInputState.isSending,
          hasText: hasText,
          hasAttachment: hasAttachment,
          speechUiState: chatInputState.speechUiState,
        ),
        size: iconSize,
        color: InputWidgetBuilders.getActionColor(
          theme: theme,
          isSending: chatInputState.isSending,
          hasText: hasText,
          hasAttachment: hasAttachment,
          speechUiState: chatInputState.speechUiState,
        ),
      ),
    );
  }
}
