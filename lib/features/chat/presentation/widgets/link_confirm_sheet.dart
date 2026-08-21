import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/link_launcher.dart';
import 'package:chatorai/shared/utils/message_dialogs.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/shared/widgets/premium_sheet.dart';

Future<void> showLinkConfirmSheet(
  BuildContext context, {
  required String href,
  Future<LinkLaunchResult> Function(String)? launcher,
}) async {
  if (!isHttpHttpsUrl(href)) {
    return;
  }

  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return KeyboardHandlerDialog(
        onEnter: () => Navigator.pop(ctx, true),
        onEscape: () => Navigator.pop(ctx, false),
        child: PremiumSheetShell(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: PremiumHandle()),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const PremiumAvatar(
                        icon: Icons.open_in_new,
                        glow: ChatoraiColors.orange,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.confirmOpenLink,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: ChatoraiColors.premiumText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          href,
                          style: ChatoraiFontSizes.mono(
                            12.5,
                            color: ChatoraiColors.premiumText,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: href));
                          if (ctx.mounted) {
                            SnackbarUtils.showCopySnackBar(
                              context: ctx,
                              message: l10n.linkCopied,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.copy,
                          size: 18,
                          color: ChatoraiColors.premiumTextMuted,
                        ),
                        tooltip: l10n.copy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      premiumGhostButton(
                        context: ctx,
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.linkCancel),
                      ),
                      const Spacer(),
                      premiumPrimaryButton(
                        context: ctx,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.linkOpen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (confirmed == true && context.mounted) {
    final result = await (launcher?.call(href) ?? launchExternalLink(href));
    if (result != LinkLaunchResult.opened && context.mounted) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: l10n.linkOpenFailed,
      );
    }
  }
}
