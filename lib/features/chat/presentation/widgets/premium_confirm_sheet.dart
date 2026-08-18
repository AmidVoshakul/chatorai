import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/widgets/premium_sheet.dart';

Future<bool?> showPremiumConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: PremiumSheetShell(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: PremiumHandle()),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PremiumAvatar(
                      icon: destructive
                          ? Icons.delete_outline
                          : Icons.help_outline,
                      glow: destructive
                          ? ChatoraiColors.error
                          : ChatoraiColors.orange,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: ChatoraiColors.premiumText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: ChatoraiColors.premiumTextMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    premiumTonalButton(
                      context: ctx,
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    const Spacer(),
                    if (destructive)
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: ChatoraiColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: Text(confirmLabel),
                      )
                    else
                      premiumPrimaryButton(
                        context: ctx,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(confirmLabel),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
