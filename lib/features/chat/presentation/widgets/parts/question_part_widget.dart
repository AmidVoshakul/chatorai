import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final hasAnswer =
        widget.part.answer != null && widget.part.answer!.isNotEmpty;
    final hasOptions = widget.part.options.isNotEmpty;
    // Use parsedAnswer for display (handles JSON-encoded answers)
    final displayAnswer = widget.part.parsedAnswer;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        // Theme-aware background: black for dark, white for light
        color: isDark ? Colors.black26 : Colors.white38,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // "# Question" heading
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '# Question',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hide check_circle icon when answered (no bird icon)
              if (!hasAnswer)
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.part.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ],
          ),
          if (hasAnswer && displayAnswer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.sm,
                  vertical: ChatoraiSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon(
                    //   Icons.arrow_upward,
                    //   size: 10,
                    //   color: isDark ? Colors.white70 : Colors.black,
                    // ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        displayAnswer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black,
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
