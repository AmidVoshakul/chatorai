import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorMessageBubble extends StatefulWidget {
  final String errorMessage;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;

  const ErrorMessageBubble({
    super.key,
    required this.errorMessage,
    this.onCopy,
    this.onRegenerate,
    this.onDelete,
  });

  @override
  State<ErrorMessageBubble> createState() => _ErrorMessageBubbleState();
}

class _ErrorMessageBubbleState extends State<ErrorMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: ChatoraiDurations.slow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: ChatoraiDurations.normal,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: ChatoraiColors.error,
        ),
        title: Text(localizations.areYouSureYouWantToDeleteThisMessage),
        content: Text(localizations.areYouSureYouWantToDeleteThisMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              localizations.delete,
              style: const TextStyle(color: ChatoraiColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final backgroundColor = isDark
        ? ChatoraiColors.error.withValues(alpha: 0.12)
        : ChatoraiColors.error.withValues(alpha: 0.08);

    final borderColor = ChatoraiColors.error.withValues(
      alpha: isDark ? 0.4 : 0.25,
    );

    final textColor = isDark ? ChatoraiColors.errorLight : ChatoraiColors.error;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.xs,
          ),
          padding: const EdgeInsets.all(ChatoraiSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: textColor,
                    size: ChatoraiIconSizes.lg,
                  ),
                  const SizedBox(width: ChatoraiSpacing.sm),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final hasActions =
                            constraints.maxWidth > 280 &&
                            (widget.onCopy != null ||
                                widget.onRegenerate != null ||
                                widget.onDelete != null);
                        return SelectableText(
                          widget.errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: ChatoraiSizes.errorTextLineHeight,
                          ),
                          maxLines: hasActions ? 8 : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (widget.onCopy != null ||
                  widget.onRegenerate != null ||
                  widget.onDelete != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: ChatoraiSpacing.sm,
                    left: ChatoraiSpacing.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onCopy != null)
                        _ActionChip(
                          icon: Icons.copy,
                          label: localizations.copyMessage,
                          onTap: widget.onCopy!,
                          theme: theme,
                        ),
                      const SizedBox(width: ChatoraiSpacing.xs),
                      if (widget.onRegenerate != null)
                        _ActionChip(
                          icon: Icons.refresh,
                          label: localizations.regenerate,
                          onTap: widget.onRegenerate!,
                          theme: theme,
                        ),
                      const SizedBox(width: ChatoraiSpacing.xs),
                      if (widget.onDelete != null)
                        _ActionChip(
                          icon: Icons.delete_outline,
                          label: localizations.delete,
                          onTap: _handleDelete,
                          theme: theme,
                          isDestructive: true,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive
        ? ChatoraiColors.error
        : (isDark ? ChatoraiColors.darkTextColor : ChatoraiColors.gray);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatoraiSpacing.xs,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ChatoraiIconSizes.xs, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: ChatoraiFontSizes.xs,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
