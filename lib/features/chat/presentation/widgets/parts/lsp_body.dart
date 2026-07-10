import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

class LspBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;

  const LspBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final input = part.input ?? {};
    final filePath = input['filePath'] as String? ?? 'unknown';
    final result = part.result ?? '';
    String action = input['action'] as String? ?? 'diagnostics';
    int errorCount = 0;
    int warningCount = 0;

    try {
      final json = jsonDecode(result) as Map<String, dynamic>;
      action = json['action'] as String? ?? action;
      final summary = json['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        errorCount = summary['errors'] as int? ?? 0;
        warningCount = summary['warnings'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ToolResultPart] LSP parse error: $e');
    }

    final hasDiagnostics = errorCount > 0 || warningCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              action == 'diagnostics'
                  ? (hasDiagnostics
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle)
                  : Icons.info_outline,
              size: 16,
              color: theme.colorScheme.muted,
            ),
            const SizedBox(width: 6),
            Text(
              action == 'diagnostics'
                  ? '$filePath — $errorCount errors, $warningCount warnings'
                  : '$action: $filePath',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.muted,
              ),
            ),
          ],
        ),
        if (result.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              result,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: theme.colorScheme.muted,
              ),
              maxLines: displayFull ? null : 20,
              overflow: displayFull ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
