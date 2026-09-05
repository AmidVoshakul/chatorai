import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/gui/features/chat/data/providers/chat_input_provider.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/input_widget_builders.dart';
import 'package:chatorai/gui/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputLayoutConfig {
  final BuildContext context;
  final ThemeData theme;
  final ChatInputState chatInputState;
  final Widget textField;
  final bool isMobile;
  final bool hasText;
  final bool hasAttachment;
  final double buttonSize;
  final double iconSize;
  final double sidePadding;
  final double bottomPadding;
  final VoidCallback onClearAttachedFile;
  final VoidCallback onPlusMenu;
  final VoidCallback onModelSettings;
  final VoidCallback onAgentSwitcher;
  final VoidCallback onMicrophoneAction;
  final VoidCallback onSend;
  final VoidCallback? onStopStreaming;
  final VoidCallback? onLongPressMic;
  final WidgetRef ref;
  final GlobalKey plusKey;
  final GlobalKey settingsKey;
  final GlobalKey agentKey;
  final bool isStreaming;
  final AgentDefinition currentAgent;

  const ChatInputLayoutConfig({
    required this.context,
    required this.theme,
    required this.chatInputState,
    required this.textField,
    required this.isMobile,
    required this.hasText,
    required this.hasAttachment,
    required this.buttonSize,
    required this.iconSize,
    required this.sidePadding,
    required this.bottomPadding,
    required this.onClearAttachedFile,
    required this.onPlusMenu,
    required this.onModelSettings,
    required this.onAgentSwitcher,
    required this.onMicrophoneAction,
    required this.onSend,
    this.onStopStreaming,
    this.onLongPressMic,
    required this.ref,
    required this.plusKey,
    required this.settingsKey,
    required this.agentKey,
    required this.isStreaming,
    required this.currentAgent,
  });
}

class InputLayoutBuilder {
  static Widget buildContainer({
    required bool isMobile,
    required ThemeData theme,
    required Widget child,
  }) {
    return Container(
      padding: isMobile
          ? const EdgeInsets.only(top: ChatoraiSpacing.lg)
          : const EdgeInsets.fromLTRB(
              ChatoraiSpacing.lg,
              ChatoraiSpacing.lg,
              ChatoraiSpacing.lg,
              ChatoraiSpacing.xs,
            ),
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

  static Widget buildMobileLayout({required ChatInputLayoutConfig config}) {
    final localizations = AppLocalizations.of(config.context)!;
    final theme = config.theme;
    final chatInputState = config.chatInputState;
    final isMobile = config.isMobile;
    final sidePadding = config.sidePadding;
    final bottomPadding = config.bottomPadding;
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
              onRemove: config.onClearAttachedFile,
              localizations: localizations,
            ),
          ),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 48,
            maxHeight: MediaQuery.of(config.context).size.height * 0.4,
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
            child: config.textField,
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
            context: config.context,
            theme: theme,
            chatInputState: chatInputState,
            hasText: config.hasText,
            hasAttachment: config.hasAttachment,
            buttonSize: config.buttonSize,
            iconSize: config.iconSize,
            onPlusMenu: config.onPlusMenu,
            onModelSettings: config.onModelSettings,
            onAgentSwitcher: config.onAgentSwitcher,
            onMicrophoneAction: config.onMicrophoneAction,
            onSend: config.onSend,
            onStopStreaming: config.onStopStreaming,
            onLongPressMic: config.onLongPressMic,
            ref: config.ref,
            plusKey: config.plusKey,
            settingsKey: config.settingsKey,
            agentKey: config.agentKey,
            isStreaming: config.isStreaming,
            currentAgent: config.currentAgent,
          ),
        ),
      ],
    );
  }

  static Widget buildDesktopLayout({required ChatInputLayoutConfig config}) {
    final localizations = AppLocalizations.of(config.context)!;
    final theme = config.theme;
    final chatInputState = config.chatInputState;
    final isMobile = config.isMobile;
    final buttonBorderRadius = BorderRadius.circular(ChatoraiBorderRadius.md);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InputWidgetBuilders.buildActionButton(
              key: config.plusKey,
              buttonSize: config.buttonSize,
              bgColor: theme.brightness == Brightness.dark
                  ? ChatoraiColors.inputContainerDark
                  : ChatoraiColors.inputContainerLight,
              borderRadius: buttonBorderRadius,
              onTap: config.onPlusMenu,
              tooltip: localizations.addFileTooltip,
              child: Icon(Icons.add, color: theme.iconTheme.color),
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InputWidgetBuilders.buildActionButton(
              key: config.settingsKey,
              buttonSize: config.buttonSize,
              bgColor: theme.brightness == Brightness.dark
                  ? ChatoraiColors.inputContainerDark
                  : ChatoraiColors.inputContainerLight,
              borderRadius: buttonBorderRadius,
              onTap: config.onModelSettings,
              tooltip: localizations.modelSettingsTooltip,
              child: Icon(Icons.tune, color: theme.iconTheme.color),
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InputWidgetBuilders.buildAgentButton(
              key: config.agentKey,
              theme: theme,
              currentAgent: config.currentAgent,
              borderRadius: buttonBorderRadius,
              onTap: config.onAgentSwitcher,
              tooltip: localizations.switchAgentTooltip,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        onRemove: config.onClearAttachedFile,
                        localizations: localizations,
                      ),
                    ),
                  ),
                  const SizedBox(height: ChatoraiSpacing.xs),
                ],
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(config.context).size.height * 0.4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? ChatoraiColors.inputContainerDark
                            : ChatoraiColors.inputContainerLight,
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.md,
                        ),
                      ),
                      child: config.textField,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildActionOrStopButton(
              context: config.context,
              theme: theme,
              chatInputState: chatInputState,
              hasText: config.hasText,
              hasAttachment: config.hasAttachment,
              buttonSize: config.buttonSize,
              iconSize: config.iconSize,
              onMicrophoneAction: config.onMicrophoneAction,
              onSend: config.onSend,
              onStopStreaming: config.onStopStreaming,
              onLongPressMic: config.onLongPressMic,
              ref: config.ref,
              isStreaming: config.isStreaming,
              borderRadius: buttonBorderRadius,
            ),
          ),
        ],
      ),
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
    final buttonBorderRadius = BorderRadius.circular(ChatoraiBorderRadius.md);
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
          borderRadius: buttonBorderRadius,
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
          borderRadius: buttonBorderRadius,
          onTap: onModelSettings,
          tooltip: localizations.modelSettingsTooltip,
          child: Icon(Icons.tune, size: iconSize, color: theme.iconTheme.color),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        InputWidgetBuilders.buildAgentButton(
          key: agentKey,
          theme: theme,
          currentAgent: currentAgent,
          borderRadius: buttonBorderRadius,
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
          borderRadius: buttonBorderRadius,
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
    BorderRadius? borderRadius,
  }) {
    if (isStreaming) {
      return InputWidgetBuilders.buildStopButton(
        context,
        ref,
        onStopStreaming: onStopStreaming,
        borderRadius: borderRadius,
      );
    }
    final isListening =
        chatInputState.speechUiState == SpeechUiState.listening ||
        chatInputState.speechUiState == SpeechUiState.preparing;
    final isIdle = chatInputState.speechUiState == SpeechUiState.idle;
    final showGradient = (hasText || hasAttachment) || !isIdle;

    final localizations = AppLocalizations.of(context)!;
    final actionTooltip = isListening
        ? localizations.stopListening
        : (hasText || hasAttachment)
        ? localizations.sendMessage
        : localizations.startListening;

    return InputWidgetBuilders.buildActionButton(
      buttonSize: buttonSize,
      tooltip: actionTooltip,
      borderRadius: borderRadius,
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
