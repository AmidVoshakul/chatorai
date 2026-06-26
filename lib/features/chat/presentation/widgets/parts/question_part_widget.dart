import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class QuestionPartWidget extends StatefulWidget {
  final QuestionPart part;
  final ValueChanged<String>? onAnswer;

  const QuestionPartWidget({super.key, required this.part, this.onAnswer});

  @override
  State<QuestionPartWidget> createState() => _QuestionPartWidgetState();
}

class _QuestionPartWidgetState extends State<QuestionPartWidget> {
  final _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnswer =
        widget.part.answer != null && widget.part.answer!.isNotEmpty;
    final hasOptions = widget.part.options.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: hasAnswer
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                hasAnswer ? Icons.check_circle : Icons.help_outline,
                size: 16,
                color: hasAnswer
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.part.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.sm,
                  vertical: ChatoraiSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.part.answer!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!hasAnswer && hasOptions) ...[
            const SizedBox(height: ChatoraiSpacing.sm),
            ...widget.part.options.map(
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _OptionButton(
                  label: option,
                  onTap: widget.onAnswer != null
                      ? () => widget.onAnswer!(option)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: widget.onAnswer != null
                  ? () => setState(() => _showCustomInput = !_showCustomInput)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showCustomInput ? Icons.expand_less : Icons.edit,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showCustomInput ? 'Hide custom input' : 'Custom answer...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (_showCustomInput) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      decoration: InputDecoration(
                        hintText: 'Type your answer...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ChatoraiBorderRadius.sm,
                          ),
                        ),
                        counterText: '',
                      ),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      minLines: 1,
                      maxLength: 1000,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed:
                        _customController.text.trim().isNotEmpty &&
                            widget.onAnswer != null
                        ? () => widget.onAnswer!(_customController.text.trim())
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!hasAnswer && !hasOptions) ...[
            const SizedBox(height: ChatoraiSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.sm,
                        ),
                      ),
                      counterText: '',
                    ),
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 1000,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed:
                      _customController.text.trim().isNotEmpty &&
                          widget.onAnswer != null
                      ? () => widget.onAnswer!(_customController.text.trim())
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OptionButton({required this.label, this.onTap});

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
          color: theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
