import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/gui/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/gui/features/settings/widgets/auto_approve/auto_approve_helpers.dart';
import 'package:chatorai/gui/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Add/edit exception rule dialog.
///
/// Extracted from [_AddExceptionDialog] in auto_approve_screen.dart.
class AutoApproveRuleDialog extends StatefulWidget {
  const AutoApproveRuleDialog({
    super.key,
    required this.category,
    required this.localizations,
    required this.onSave,
  });

  final AutoApproveCategory category;
  final AppLocalizations localizations;
  final void Function(String pattern, String action) onSave;

  @override
  State<AutoApproveRuleDialog> createState() => _AutoApproveRuleDialogState();
}

class _AutoApproveRuleDialogState extends State<AutoApproveRuleDialog> {
  late final TextEditingController _patternController = TextEditingController();
  String _selectedAction = PermissionAction.ask.name;

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isFile = widget.category.isFileCategory;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 520,
        ),
        child: Container(
          decoration: premiumDialog(isDark),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ChatoraiSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with orange icon badge, title, subtitle and close.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ChatoraiColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.md,
                        ),
                      ),
                      child: Icon(
                        widget.category.isShellCategory
                            ? Icons.terminal_rounded
                            : Icons.folder_outlined,
                        color: ChatoraiColors.orange,
                        size: ChatoraiIconSizes.lg,
                      ),
                    ),
                    const SizedBox(width: ChatoraiSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.isShellCategory
                                ? widget.localizations.addCommand
                                : widget.localizations.addPath,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.xl,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? ChatoraiColors.pureWhite
                                  : ChatoraiColors.pureBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.category.label,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.sm,
                              color: isDark
                                  ? ChatoraiColors.darkSecondaryTextColor
                                  : ChatoraiColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: ChatoraiIconSizes.md,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: widget.localizations.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: ChatoraiSpacing.lg),
                Container(
                  height: 1,
                  color: isDark
                      ? ChatoraiColors.darkInputBorder
                      : ChatoraiColors.inputBorder.withValues(alpha: 0.6),
                ),
                const SizedBox(height: ChatoraiSpacing.lg),
                // Pattern field — high-contrast, no left icon, single browse icon on right.
                TextField(
                  controller: _patternController,
                  autofocus: true,
                  style: TextStyle(
                    fontFamily: isFile ? 'monospace' : null,
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                  decoration:
                      premiumFieldDecoration(
                        label: widget.category.isShellCategory
                            ? widget
                                  .localizations
                                  .autoApproveCommandPatternLabel
                            : widget.localizations.autoApprovePathPatternLabel,
                        hint: widget.category.isShellCategory
                            ? widget.localizations.autoApproveCommandPatternHint
                            : widget.localizations.autoApprovePathPatternHint,
                        helper: isFile
                            ? widget.localizations.autoApprovePatternHintFile
                            : widget
                                  .localizations
                                  .autoApprovePatternHintCommand,
                        isDark: isDark,
                      ).copyWith(
                        suffixIcon: isFile
                            ? Tooltip(
                                message: widget
                                    .localizations
                                    .autoApproveBrowseDirectory,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.folder_open_rounded,
                                    size: ChatoraiIconSizes.md,
                                    color: ChatoraiColors.orange,
                                  ),
                                  onPressed: () async {
                                    final path = await FilePicker.platform
                                        .getDirectoryPath();
                                    if (path != null && mounted) {
                                      setState(
                                        () => _patternController.text = path,
                                      );
                                    }
                                  },
                                ),
                              )
                            : null,
                      ),
                  onSubmitted: (_) {
                    final pattern = _patternController.text.trim();
                    if (pattern.isNotEmpty) {
                      widget.onSave(pattern, _selectedAction);
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: ChatoraiSpacing.lg),
                // Action dropdown — same high-contrast fill/border as pattern field.
                DropdownButtonFormField<String>(
                  initialValue: sanitizeAction(_selectedAction),
                  decoration: InputDecoration(
                    labelText: widget.localizations.autoApproveActionLabel,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2F2F2F) : Colors.white,
                    labelStyle: TextStyle(
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ChatoraiBorderRadius.md,
                      ),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ChatoraiBorderRadius.md,
                      ),
                      borderSide: const BorderSide(
                        color: ChatoraiColors.orange,
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ChatoraiSpacing.md,
                      vertical: ChatoraiSpacing.md,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF262626)
                      : ChatoraiColors.lightCard,
                  items: PermissionAction.values.map((action) {
                    final label = switch (action) {
                      PermissionAction.allow =>
                        widget.localizations.defaultAllow,
                      PermissionAction.ask => widget.localizations.defaultAsk,
                      PermissionAction.deny => widget.localizations.defaultDeny,
                    };
                    final color = switch (action) {
                      PermissionAction.allow => ChatoraiColors.success,
                      PermissionAction.ask => ChatoraiColors.warning,
                      PermissionAction.deny => ChatoraiColors.error,
                    };
                    return DropdownMenuItem<String>(
                      value: action.name,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: ChatoraiSpacing.sm),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedAction = value);
                  },
                ),
                const SizedBox(height: ChatoraiSpacing.xl),
                // Footer
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                          side: BorderSide(
                            color: isDark
                                ? ChatoraiColors.darkInputBorder
                                : ChatoraiColors.inputBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ChatoraiBorderRadius.md,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: ChatoraiSpacing.md,
                          ),
                        ),
                        child: Text(widget.localizations.cancel),
                      ),
                    ),
                    const SizedBox(width: ChatoraiSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final pattern = _patternController.text.trim();
                          if (pattern.isEmpty) return;
                          widget.onSave(pattern, _selectedAction);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: ChatoraiColors.orange,
                          foregroundColor: ChatoraiColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ChatoraiBorderRadius.md,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: ChatoraiSpacing.md,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(widget.localizations.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
