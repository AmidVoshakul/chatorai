import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/providers/chat/chat_input_provider.dart';

class ChatInputAttachedFilePreview extends ConsumerWidget {
  final bool isMobileLayout;

  const ChatInputAttachedFilePreview({super.key, required this.isMobileLayout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatInputProvider);
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
            constraints: BoxConstraints(maxWidth: isMobileLayout ? 120 : 150),
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
            onPressed: () {
              ref.read(chatInputProvider.notifier).clearAttachedFile();
            },
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
}
