import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/core/permission/permission_service.dart';

typedef PermissionReplyCallback = void Function(PermissionReply reply);

class PermissionDialog extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> patterns;
  final String? customBody;
  final PermissionReplyCallback onReply;

  const PermissionDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.patterns,
    this.customBody,
    required this.onReply,
  });

  @override
  ConsumerState<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends ConsumerState<PermissionDialog> {
  bool _showAlwaysConfirmation = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_showAlwaysConfirmation) {
      return _buildAlwaysConfirmation(context, localizations, colorScheme);
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (widget.customBody != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.customBody!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (widget.patterns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              localizations.permissionDialogPatterns,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...widget.patterns.map(
              (pattern) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  pattern,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.permissionReject),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _showAlwaysConfirmation = true),
          child: Text(localizations.permissionAlways),
        ),
        FilledButton(
          onPressed: () {
            widget.onReply(PermissionReply.once);
            Navigator.of(context).pop();
          },
          child: const Text('Allow once'),
        ),
      ],
    );
  }

  Widget _buildAlwaysConfirmation(
    BuildContext context,
    AppLocalizations? localizations,
    ColorScheme colorScheme,
  ) {
    return AlertDialog(
      title: Text(localizations?.permissionAlwaysConfirm ?? 'Always allow'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will allow "${widget.title}" until the app is restarted.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.patterns.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...widget.patterns.map(
              (p) => Text(
                p,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showAlwaysConfirmation = false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onReply(PermissionReply.always);
            Navigator.of(context).pop();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
