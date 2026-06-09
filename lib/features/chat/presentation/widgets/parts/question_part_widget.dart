import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class QuestionPartWidget extends StatelessWidget {
  final QuestionPart part;
  final ValueChanged<String>? onAnswer;

  const QuestionPartWidget({super.key, required this.part, this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            part.question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (part.options.isNotEmpty) ...[
            const SizedBox(height: ChatoraiSpacing.sm),
            ...part.options.map(
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _OptionButton(
                  label: option,
                  isSelected: part.answer == option,
                  onTap: onAnswer != null ? () => onAnswer!(option) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: ChatoraiSpacing.md,
          vertical: ChatoraiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: ChatoraiIconSizes.md,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
