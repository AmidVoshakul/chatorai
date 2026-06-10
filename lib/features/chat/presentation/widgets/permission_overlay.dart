import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Bridges [PermissionService.onAsked] → UI dialog.
class PermissionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PermissionOverlay({super.key, required this.child});

  @override
  ConsumerState<PermissionOverlay> createState() => _PermissionOverlayState();
}

class _PermissionOverlayState extends ConsumerState<PermissionOverlay> {
  StreamSubscription<PermissionRequest>? _sub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _sub ??= ref.read(permissionServiceProvider).onAsked.listen(_onRequest);
  }

  Future<void> _onRequest(PermissionRequest req) async {
    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: START for tool=${req.toolName}',
    );
    if (!mounted) {
      LogTags.permission.logWarning(
        'PermissionOverlay._onRequest: Widget not mounted, aborting',
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: Showing dialog for tool=${req.toolName}',
    );

    final reply = await showDialog<PermissionReply>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(req.toolName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.permissionDialogPatterns,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...req.patterns.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  p,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, PermissionReply.once),
            child: Text(l10n.permissionOnce),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, PermissionReply.always),
            child: Text(l10n.permissionAlways),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, PermissionReply.reject),
            child: Text(l10n.permissionReject),
          ),
        ],
      ),
    );

    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: Dialog closed with reply=$reply for tool=${req.toolName}',
    );

    if (!mounted) {
      LogTags.permission.logWarning(
        'PermissionOverlay._onRequest: Widget not mounted after dialog, aborting reply',
      );
      return;
    }

    final service = ref.read(permissionServiceProvider);
    if (reply == null) {
      LogTags.permission.logInfo(
        'PermissionOverlay._onRequest: Reply=reject (null) for tool=${req.toolName}',
      );
      service.reply(req.id, PermissionReply.reject);
    } else {
      LogTags.permission.logInfo(
        'PermissionOverlay._onRequest: Reply=$reply for tool=${req.toolName}',
      );
      service.reply(req.id, reply);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
