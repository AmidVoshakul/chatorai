import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';

enum MessageActionType { delete, edit, copy, share, copyChat, regenerate }

enum EditMessageResult { cancelled, saved, savedAndSent }

class EditMessageResultWithContent {
  final EditMessageResult result;
  final String? newContent;

  EditMessageResultWithContent({required this.result, this.newContent});
}

class MessageAction {
  final IconData icon;
  final String label;
  final Map<String, String> localizedLabel;
  final MessageActionType action;
  final Color color;

  MessageAction({
    required this.icon,
    required this.label,
    required this.localizedLabel,
    required this.action,
    required this.color,
  });

  String getLocalizedLabel(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizedLabel[localizations.localeName] ?? label;
  }
}

List<MessageAction> getChatActions(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;

  return [
    MessageAction(
      icon: Icons.copy_all,
      label: localizations.copyChat,
      localizedLabel: {'en': 'Copy Chat', 'ru': 'Копировать чат'},
      action: MessageActionType.copyChat,
      color: Colors.green,
    ),
    MessageAction(
      icon: Icons.share,
      label: localizations.shareChat,
      localizedLabel: {'en': 'Share', 'ru': 'Поделиться'},
      action: MessageActionType.share,
      color: Colors.blue,
    ),
    MessageAction(
      icon: Icons.edit,
      label: localizations.renameChat,
      localizedLabel: {'en': 'Rename', 'ru': 'Переименовать'},
      action: MessageActionType.edit,
      color: Colors.orange,
    ),
    MessageAction(
      icon: Icons.delete,
      label: localizations.deleteChat,
      localizedLabel: {'en': 'Delete', 'ru': 'Удалить'},
      action: MessageActionType.delete,
      color: Colors.red,
    ),
  ];
}
