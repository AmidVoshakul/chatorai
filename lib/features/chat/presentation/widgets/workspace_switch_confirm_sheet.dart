import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/features/chat/presentation/widgets/premium_confirm_sheet.dart';

Future<bool?> showWorkspaceSwitchConfirmSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showPremiumConfirmSheet(
    context: context,
    title: l10n.switchWorkspaceTitle,
    message: l10n.currentSessionWillBeStopped,
    confirmLabel: l10n.continueText,
    destructive: false,
  );
}
