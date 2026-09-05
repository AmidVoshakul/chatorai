import 'package:chatorai/gui/shared/utils/message_action.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<EditMessageResult> editMessage({
  required String currentContent,
  required BuildContext context,
}) async {
  final TextEditingController controller = TextEditingController(
    text: currentContent,
  );
  final localizations = AppLocalizations.of(context)!;

  final EditMessageResult? result = await showDialog<EditMessageResult>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(localizations.edit),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: localizations.enterYourMessage,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
            },
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.saved);
            },
            child: Text(localizations.save),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.savedAndSent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(localizations.saveAndSend),
          ),
        ],
      );
    },
  );

  return result ?? EditMessageResult.cancelled;
}

Future<EditMessageResultWithContent> editMessageWithResult({
  required String currentContent,
  required BuildContext context,
}) async {
  final TextEditingController controller = TextEditingController(
    text: currentContent,
  );
  final localizations = AppLocalizations.of(context)!;

  final EditMessageResult? result = await showDialog<EditMessageResult>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(localizations.edit),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: localizations.enterYourMessage,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
            },
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.saved);
            },
            child: Text(localizations.save),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(EditMessageResult.savedAndSent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(localizations.saveAndSend),
          ),
        ],
      );
    },
  );

  return EditMessageResultWithContent(
    result: result ?? EditMessageResult.cancelled,
    newContent: controller.text,
  );
}
