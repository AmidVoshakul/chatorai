import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/permissions/permission_service.dart';

/// Callback type for permission dialog replies.
typedef PermissionReplyCallback = void Function(PermissionReply reply);

/// Modal dialog asking the user to approve/deny a tool action.
class PermissionDialog extends ConsumerWidget {
  final String title;
  final List<String> patterns;
  final PermissionReplyCallback onReply;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.patterns,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patterns.isNotEmpty) ...[
            Text(
              localizations?.permissionDialogPatterns ??
                  'Requesting access to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...patterns.map(
              (pattern) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  pattern,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onReply(PermissionReply.once),
          child: Text(localizations?.permissionOnce ?? 'Once'),
        ),
        OutlinedButton(
          onPressed: () => onReply(PermissionReply.always),
          child: Text(localizations?.permissionAlways ?? 'Always allow'),
        ),
        TextButton(
          onPressed: () => onReply(PermissionReply.reject),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: Text(localizations?.permissionReject ?? 'Reject'),
        ),
      ],
    );
  }
}
