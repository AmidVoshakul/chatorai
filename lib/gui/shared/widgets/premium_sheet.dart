import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

const BorderRadius _premiumSheetTopRadius = BorderRadius.vertical(
  top: Radius.circular(ChatoraiBorderRadius.xl),
);

/// Simple dark panel with a solid border (no gradient, no blur).
class PremiumSheetShell extends StatelessWidget {
  final Widget child;

  const PremiumSheetShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChatoraiColors.premiumSurface,
        borderRadius: _premiumSheetTopRadius,
        border: const Border(
          top: BorderSide(color: ChatoraiColors.premiumBorderSoft, width: 1),
        ),
      ),
      child: ClipRRect(borderRadius: _premiumSheetTopRadius, child: child),
    );
  }
}

/// Metallic pill handle.
class PremiumHandle extends StatelessWidget {
  const PremiumHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        gradient: ChatoraiGradients.metallic,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
        boxShadow: [
          BoxShadow(
            color: ChatoraiColors.pureBlack.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Circular icon badge with a brand accent gradient and a soft glow.
class PremiumAvatar extends StatelessWidget {
  final IconData icon;
  final Color glow;

  const PremiumAvatar({super.key, required this.icon, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: ChatoraiGradients.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: ChatoraiColors.pureWhite, size: 22),
    );
  }
}

/// Small-caps section label.
Widget premiumSectionLabel(BuildContext context, String text) {
  return Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.6,
      fontWeight: FontWeight.w700,
      color: ChatoraiColors.premiumTextMuted,
    ),
  );
}

/// Pill button with a brand accent gradient background and a soft glow.
Widget premiumPrimaryButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: ChatoraiGradients.accent,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
      boxShadow: [
        BoxShadow(
          color: ChatoraiColors.orange.withValues(alpha: 0.4),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: ChatoraiColors.pureWhite,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      child: child,
    ),
  );
}

/// Dark tonal pill button for secondary actions.
Widget premiumTonalButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return FilledButton.tonal(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: ChatoraiColors.premiumSurfaceRaised,
      foregroundColor: ChatoraiColors.premiumText,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
      ),
      side: BorderSide(color: ChatoraiColors.premiumBorderSoft),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    child: child,
  );
}

/// Quiet ghost button for dismissive actions.
Widget premiumGhostButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: ChatoraiColors.premiumTextMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    child: child,
  );
}
