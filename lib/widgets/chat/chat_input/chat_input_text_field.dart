import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers/chat/chat_input_provider.dart';

class ChatInputTextField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int maxLines;
  final bool enabled;
  final bool isMobile;

  const ChatInputTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.maxLines,
    required this.enabled,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final chatInputState = ref.watch(chatInputProvider);

    final isSpellCheckSupported =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return TextField(
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
              hintText: chatInputState.attachedFilePath != null
                  ? localizations.typeYourMessage
                  : localizations.typeYourMessage,
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
              hintText: localizations.typeYourMessage,
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
      textInputAction: isMobile ? TextInputAction.newline : null,
      enabled: enabled,
    );
  }
}
