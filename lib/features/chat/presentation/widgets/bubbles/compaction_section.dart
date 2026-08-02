import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/widgets/shimmer_mask.dart';
import 'package:flutter/material.dart';

/// Visually separates a compaction summary from ordinary conversation turns.
///
/// Renders a themed `------- compaction -------` divider on top, then either a
/// shimmer "compacting" indicator while compaction is in-flight or the summary
/// bubble supplied via [child].
class CompactionSection extends StatelessWidget {
  final bool isLoading;
  final Widget? child;

  const CompactionSection({super.key, required this.isLoading, this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CompactionDivider(),
        if (isLoading)
          const _CompactionLoadingIndicator()
        else
          child ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _CompactionDivider extends StatelessWidget {
  const _CompactionDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark
        ? ChatoraiColors.darkInputBorder
        : ChatoraiColors.inputBorder;

    Widget line() => Container(height: 1, color: lineColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: line()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'compaction',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: line()),
        ],
      ),
    );
  }
}

class _CompactionLoadingIndicator extends StatelessWidget {
  const _CompactionLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.md,
        vertical: ChatoraiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: ChatoraiBorderWidth.thinBold,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: ShimmerMask(
              duration: const Duration(milliseconds: 1500),
              baseColor: theme.colorScheme.primary,
              child: Text(
                l10n.compactingIndicator,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
