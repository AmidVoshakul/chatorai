import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared premium building blocks for the settings management screens
/// (Agents Instructions, Skills, …). Centralised here so the screens stay DRY
/// and the tokens (dark hairline, borderless dark cards, orange accent) live in
/// one place.

/// Unified premium card — same luxury gradient as Auto-Approve tools.
/// Single source of truth (DRY) for all settings cards: Skills, MCP,
/// Agents Instructions, Provider, Appearance, Accessibility, etc.
BoxDecoration premiumCard(bool isDark) => BoxDecoration(
  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
  border: Border.all(
    color: isDark ? ChatoraiColors.darkInputBorder : ChatoraiColors.inputBorder,
    width: ChatoraiBorderWidth.thin,
  ),
  boxShadow: isDark ? ChatoraiShadows.darkShadow : ChatoraiShadows.cardShadow,
  gradient: isDark
      ? const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF262626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
);

BoxDecoration premiumDialog(bool isDark) => premiumCard(
  isDark,
).copyWith(borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl));

InputDecoration premiumFieldDecoration({
  required String label,
  String? hint,
  String? helper,
  required bool isDark,
}) {
  final helperColor = isDark
      ? ChatoraiColors.darkSecondaryTextColor.withAlpha(140)
      : ChatoraiColors.secondaryTextColor.withAlpha(140);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintMaxLines: 12,
    helperText: helper,
    helperStyle: TextStyle(fontSize: 11, color: helperColor),
    helperMaxLines: 2,
    contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 2),
  );
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PremiumCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: premiumCard(isDark),
      child: child,
    );
  }
}

/// A hairline divider that stays *dark* in dark mode (never white) and a soft
/// neutral in light mode. Used under the tab bar.
Color hairlineColor(bool isDark) =>
    isDark ? ChatoraiColors.darkInputBorder : ChatoraiColors.inputBorder;

Color titleColor(bool isDark) =>
    isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack;

Color subtleColor(bool isDark) => isDark
    ? ChatoraiColors.darkSecondaryTextColor
    : ChatoraiColors.secondaryTextColor;

/// Compact unified tab bar — single source of truth for all category tabs
/// (Skills, MCP, Agents, Config, Auto-Approve). Height 40 (was 48) for a
/// denser premium look. DRY: use everywhere instead of duplicating TabBar.
const double kCompactTabHeight = 40.0;

TabBar unifiedTabBar({
  required List<Widget> tabs,
  required bool isDark,
  TabController? controller,
  void Function(int)? onTap,
  bool isScrollable = false,
}) => TabBar(
  controller: controller,
  onTap: onTap,
  tabs: tabs,
  isScrollable: isScrollable,
  indicatorColor: ChatoraiColors.orange,
  indicatorSize: TabBarIndicatorSize.tab,
  dividerColor: Colors.transparent,
  labelColor: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
  unselectedLabelColor: isDark
      ? ChatoraiColors.darkSecondaryTextColor
      : ChatoraiColors.secondaryTextColor,
  labelStyle: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: ChatoraiFontSizes.base,
  ),
  unselectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: ChatoraiFontSizes.base,
  ),
  labelPadding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.md),
  overlayColor: WidgetStateProperty.all(Colors.transparent),
);

PreferredSizeWidget unifiedTabContainer({
  required TabBar tabBar,
  required bool isDark,
}) => PreferredSize(
  preferredSize: const Size.fromHeight(kCompactTabHeight),
  child: DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
      ),
    ),
    child: SizedBox(height: kCompactTabHeight, child: tabBar),
  ),
);

/// Unified marketplace search — identical in MCP and Skills.
/// Premium compact field with high-contrast fill and orange focus.
InputDecoration marketplaceSearchDecoration({
  required bool isDark,
  required String hintText,
}) => InputDecoration(
  prefixIcon: Icon(
    Icons.search_rounded,
    size: 18,
    color: isDark
        ? ChatoraiColors.darkSecondaryTextColor
        : ChatoraiColors.secondaryTextColor,
  ),
  hintText: hintText,
  hintStyle: TextStyle(
    color: isDark ? const Color(0xFF8A8A8A) : const Color(0xFF9A9A9A),
    fontSize: ChatoraiFontSizes.base,
  ),
  filled: true,
  fillColor: isDark ? const Color(0xFF2F2F2F) : Colors.white,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
    borderSide: BorderSide(
      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
      width: ChatoraiBorderWidth.thin,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
    borderSide: const BorderSide(color: ChatoraiColors.orange, width: 1.4),
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
    borderSide: BorderSide(
      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
    ),
  ),
);

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
  final int maxColumns;

  const CardGrid({super.key, required this.children, this.maxColumns = 3});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMax = maxColumns.clamp(1, 3);
        final crossCount = constraints.maxWidth >= 720
            ? effectiveMax
            : constraints.maxWidth >= 480
            ? effectiveMax.clamp(1, 2)
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

/// Compact premium pill for marketplace category filters (MCP & Skills).
/// Unified, dense and expensive — replaces the previous large 14/8 chip.
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
      child: AnimatedContainer(
        duration: ChatoraiDurations.fast,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? ChatoraiColors.orange
              : (isDark ? const Color(0xFF262626) : Colors.white),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
          border: Border.all(
            color: selected
                ? ChatoraiColors.orange
                : (isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE8E8E8)),
            width: ChatoraiBorderWidth.thin,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ChatoraiColors.orange.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.md,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.15,
            height: 1.1,
            color: fg,
          ),
        ),
      ),
    );
  }
}
