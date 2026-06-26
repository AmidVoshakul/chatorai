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
  StreamSubscription<QuestionRequest>? _questionSub;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final service = ref.read(permissionServiceProvider);
    _sub ??= service.onAsked.listen(_onRequest);
    _questionSub ??= service.onQuestionAsked.listen(_onQuestionRequest);
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

    final l10n = AppLocalizations.of(context)!;
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

  Future<void> _onQuestionRequest(QuestionRequest req) async {
    LogTags.permission.logInfo(
      'PermissionOverlay._onQuestionRequest: START id=${req.id}, question="${req.question}"',
    );

    _customController.clear();
    String? selectedOption;

    final answer = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.help_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Question', style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (req.options.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...req.options.map(
                        (option) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedOption = option;
                                _customController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selectedOption == option
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      )
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedOption == option
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedOption == option
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: selectedOption == option
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(option),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                    ],
                    TextField(
                      controller: _customController,
                      decoration: InputDecoration(
                        labelText: req.options.isNotEmpty
                            ? 'Or type your answer...'
                            : 'Your answer',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 1000,
                      onChanged: (_) {
                        setDialogState(() {
                          selectedOption = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Skip'),
                ),
                FilledButton(
                  onPressed: () {
                    if (_customController.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, _customController.text.trim());
                    } else if (selectedOption != null) {
                      Navigator.pop(ctx, selectedOption);
                    }
                  },
                  child: const Text('Answer'),
                ),
              ],
            );
          },
        );
      },
    );

    LogTags.permission.logInfo(
      'PermissionOverlay._onQuestionRequest: answer="$answer" for id=${req.id}',
    );

    if (!mounted) return;
    final service = ref.read(permissionServiceProvider);
    if (answer == null) {
      service.cancelPendingQuestion(req.id);
    } else if (answer.isEmpty) {
      service.cancelPendingQuestion(req.id);
    } else {
      service.answerQuestion(req.id, answer);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _questionSub?.cancel();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
