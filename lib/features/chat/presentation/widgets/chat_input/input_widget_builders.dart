import 'dart:io' show Platform;

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputWidgetBuilders {
  static int computeMaxLines(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    return (maxHeight / 24).floor().clamp(1, 12);
  }

  static bool isMobileLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static Widget buildTextField({
    Key? key,
    required TextEditingController controller,
    required FocusNode? focusNode,
    required int maxLines,
    required bool isMobile,
    required bool enabled,
    required ThemeData theme,
    required AppLocalizations localizations,
    required String hintText,
    Map<ShortcutActivator, VoidCallback>? keyboardBindings,
  }) {
    final isSpellCheckSupported = Platform.isAndroid || Platform.isIOS;

    return CallbackShortcuts(
      bindings: keyboardBindings ?? const {},
      child: Focus(
        onKeyEvent: (node, event) => KeyEventResult.ignored,
        child: TextField(
          key: key,
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: maxLines,
          spellCheckConfiguration: isSpellCheckSupported
              ? const SpellCheckConfiguration()
              : null,
          decoration: isMobile
              ? InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.lg,
                    vertical: ChatoraiSpacing.md,
                  ),
                )
              : InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.lg,
                    vertical: ChatoraiSpacing.md,
                  ),
                ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: ChatoraiFontSizes.lg,
            height: 1.2,
          ),
          textInputAction: TextInputAction.newline,
          enabled: enabled,
        ),
      ),
    );
  }

  static Widget buildActionButton({
    Key? key,
    required double buttonSize,
    required Widget child,
    Gradient? gradient,
    Color? bgColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? tooltip,
  }) {
    return Container(
      key: key,
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? bgColor : null,
        borderRadius: BorderRadius.circular(buttonSize / 2),
      ),
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonSize / 2),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  static Widget buildStopButton(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback? onStopStreaming,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final retryAsync = ref.watch(retryCountdownProvider);
    final retryProgress = retryAsync.hasValue ? retryAsync.value : null;
    final isRetrying =
        retryProgress != null && retryProgress > 0 && retryProgress <= 1;

    return AnimatedContainer(
      duration: ChatoraiDurations.normal,
      curve: Curves.easeInOut,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isRetrying
            ? null
            : LinearGradient(
                colors: [
                  ChatoraiColors.error,
                  ChatoraiColors.error.withValues(alpha: 0.8),
                ],
              ),
        color: isRetrying ? Colors.transparent : null,
        shape: BoxShape.circle,
        boxShadow: isRetrying ? null : ChatoraiShadows.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRetrying)
            CircularProgressIndicator(
              value: retryProgress,
              strokeWidth: ChatoraiBorderWidth.bold,
              strokeCap: StrokeCap.round,
              backgroundColor: ChatoraiColors.error.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                ChatoraiColors.error,
              ),
            ),
          IconButton(
            onPressed: onStopStreaming,
            icon: Icon(
              Icons.stop,
              size: isRetrying ? ChatoraiIconSizes.md : ChatoraiIconSizes.lg,
              color: ChatoraiColors.pureWhite,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isRetrying
                ? localizations.cancellingRetryTooltip
                : localizations.stopGenerationTooltip,
          ),
        ],
      ),
    );
  }

  static Widget buildAttachedFilePreview({
    required ChatInputState state,
    required bool isMobile,
    required VoidCallback onRemove,
    required AppLocalizations localizations,
  }) {
    if (state.attachedFilePath == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: ChatoraiSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.sm,
        vertical: ChatoraiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ChatoraiColors.link.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(color: ChatoraiColors.link.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.attachedImageType != null ? Icons.image : Icons.attach_file,
            size: ChatoraiIconSizes.xs,
            color: ChatoraiColors.link,
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 120 : 150),
            child: Text(
              state.attachedFileName ?? 'file',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: ChatoraiColors.link,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          IconButton(
            icon: Icon(
              Icons.close,
              size: ChatoraiFontSizes.sm,
              color: ChatoraiColors.error,
            ),
            onPressed: onRemove,
            tooltip: localizations.removeFileTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: ChatoraiSpacing.md,
              minHeight: ChatoraiSpacing.md,
            ),
            splashRadius: ChatoraiSpacing.sm,
          ),
        ],
      ),
    );
  }

  static Widget buildAgentButton({
    required Key key,
    required ThemeData theme,
    required AgentDefinition currentAgent,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Container(
      key: key,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? ChatoraiColors.inputContainerDark
            : ChatoraiColors.inputContainerLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Center(
              child: Text(
                currentAgent.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData getActionIcon({
    required bool isSending,
    required bool hasText,
    required bool hasAttachment,
    required SpeechUiState speechUiState,
  }) {
    if (isSending) return Icons.autorenew;
    if (speechUiState == SpeechUiState.listening ||
        speechUiState == SpeechUiState.preparing) {
      return Icons.stop;
    }
    if (hasText || hasAttachment) return Icons.send;
    return Icons.mic;
  }

  static Color getActionColor({
    required ThemeData theme,
    required bool isSending,
    required bool hasText,
    required bool hasAttachment,
    required SpeechUiState speechUiState,
  }) {
    if (isSending) return ChatoraiColors.pureWhite;
    if (speechUiState == SpeechUiState.listening ||
        speechUiState == SpeechUiState.preparing) {
      return ChatoraiColors.error;
    }
    if (speechUiState == SpeechUiState.error ||
        speechUiState == SpeechUiState.noSpeech) {
      return ChatoraiColors.error;
    }
    if (hasText || hasAttachment) return ChatoraiColors.pureWhite;
    return theme.iconTheme.color ?? ChatoraiColors.pureBlack;
  }
}
