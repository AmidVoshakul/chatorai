import 'package:chatorai/gui/features/chat/presentation/widgets/premium_confirm_sheet.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
