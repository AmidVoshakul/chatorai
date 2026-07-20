import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared premium building blocks for the settings management screens
/// (Agents Instructions, Skills, …). Centralised here so the screens stay DRY
/// and the tokens (dark hairline, borderless dark cards, orange accent) live in
/// one place.

/// Card surface with NO border in dark mode (the scaffold/card contrast does
/// the separating), and a whisper-thin border only in light mode where the
/// surfaces are too close to read otherwise.
BoxDecoration premiumCard(bool isDark) => BoxDecoration(
  color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
  border: isDark
      ? null
      : Border.all(color: ChatoraiColors.inputBorder, width: 1),
  boxShadow: isDark
      ? null
      : [
          BoxShadow(
            color: ChatoraiColors.pureBlack.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
);

/// A hairline divider that stays *dark* in dark mode (never white) and a soft
/// neutral in light mode. Used under the tab bar.
Color hairlineColor(bool isDark) =>
    isDark ? ChatoraiColors.darkInputBorder : ChatoraiColors.inputBorder;

Color titleColor(bool isDark) =>
    isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack;

Color subtleColor(bool isDark) => isDark
    ? ChatoraiColors.darkSecondaryTextColor
    : ChatoraiColors.secondaryTextColor;

/// Section heading with a helper subtitle.
class SectionTitle extends StatelessWidget {
  final String title;
  final String helper;
  final bool isDark;

  const SectionTitle({
    super.key,
    required this.title,
    required this.helper,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.xl,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: titleColor(isDark),
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Text(
          helper,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            height: 1.4,
            color: subtleColor(isDark),
          ),
        ),
      ],
    );
  }
}

/// Responsive grid: 1 / 2 / 3 columns based on available width.
class CardGrid extends StatelessWidget {
  final List<Widget> children;
  const CardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        const spacing = ChatoraiSpacing.md;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Small pill badge (scope / read-only markers).
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: ChatoraiFontSizes.xs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Full-height editor / viewer for a text file. Returns the new content on
/// save, or `null` when cancelled / read-only close.
class FileEditorDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String initialContent;
  final bool readOnly;
  final String? hintText;

  const FileEditorDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialContent,
    required this.readOnly,
    this.hintText,
  });

  @override
  State<FileEditorDialog> createState() => _FileEditorDialogState();
}

class _FileEditorDialogState extends State<FileEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialContent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.readOnly
                    ? Icons.visibility_outlined
                    : Icons.edit_outlined,
                color: ChatoraiColors.orange,
                size: ChatoraiIconSizes.lg,
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(color: titleColor(isDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              fontWeight: FontWeight.w400,
              color: subtleColor(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SizedBox(
          width: 640,
          child: TextField(
            controller: _controller,
            readOnly: widget.readOnly,
            minLines: 12,
            maxLines: 24,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.code,
            ),
            decoration: InputDecoration(
              hintText: widget.readOnly ? null : widget.hintText,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        if (!widget.readOnly)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ChatoraiColors.orange,
              foregroundColor: ChatoraiColors.pureWhite,
            ),
            onPressed: () => Navigator.pop(context, _controller.text),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(l10n.commonSave),
          ),
      ],
    );
  }
}

/// A pill-shaped, selectable filter chip used for category filters in the MCP
/// and Skills marketplaces. Selected chips use the accent orange fill.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? ChatoraiColors.pureWhite
        : (isDark
              ? ChatoraiColors.darkSecondaryTextColor
              : ChatoraiColors.secondaryTextColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? ChatoraiColors.orange
              : (isDark
                    ? ChatoraiColors.darkInputFill
                    : ChatoraiColors.inputFill),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
          border: Border.all(
            color: selected
                ? ChatoraiColors.orange
                : (isDark
                      ? ChatoraiColors.darkInputBorder
                      : ChatoraiColors.inputBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
