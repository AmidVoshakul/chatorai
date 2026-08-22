import 'package:flutter/foundation.dart';

import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/features/settings/widgets/auto_approve/auto_approve_helpers.dart';
import 'package:chatorai/features/settings/widgets/auto_approve/auto_approve_rule_dialog.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Group mapping and ordering for auto-approve categories.
///
/// Extracted from [_AutoApproveContent] in auto_approve_screen.dart.
class AutoApproveCategoryList extends StatelessWidget {
  const AutoApproveCategoryList({
    super.key,
    required this.state,
    required this.localizations,
    required this.onChanged,
  });

  static const _groupMap = <String, String>{
    'external_directory': 'file',
    'read': 'file',
    'edit': 'file',
    'write': 'file',
    'glob': 'file',
    'grep': 'file',
    'shell': 'shell',
    'webfetch': 'network',
    'websearch': 'network',
    'skill': 'agents',
    'lsp': 'agents',
    'task': 'agents',
    'todowrite': 'agents',
    'doom_loop': 'agents',
  };

  static const _groupOrder = <String>['file', 'shell', 'network', 'agents'];

  static IconData _iconFor(String id) {
    switch (id) {
      case 'external_directory':
        return Icons.folder_outlined;
      case 'read':
        return Icons.menu_book;
      case 'edit':
        return Icons.edit_note;
      case 'write':
        return Icons.save_outlined;
      case 'glob':
        return Icons.filter_center_focus;
      case 'grep':
        return Icons.find_in_page;
      case 'shell':
        return Icons.terminal;
      case 'webfetch':
        return Icons.cloud_download_outlined;
      case 'websearch':
        return Icons.travel_explore;
      case 'doom_loop':
        return Icons.autorenew;
      case 'skill':
        return Icons.auto_awesome;
      case 'lsp':
        return Icons.code;
      case 'task':
        return Icons.task_alt;
      case 'todowrite':
        return Icons.checklist;
      default:
        return Icons.extension;
    }
  }

  static String _descriptionFor(AppLocalizations l10n, String id) {
    switch (id) {
      case 'read':
        return l10n.autoApproveReadDesc;
      case 'glob':
        return l10n.autoApproveGlobDesc;
      case 'grep':
        return l10n.autoApproveGrepDesc;
      case 'shell':
        return l10n.autoApproveShellDesc;
      case 'edit':
        return l10n.autoApproveEditDesc;
      case 'write':
        return l10n.autoApproveWriteDesc;
      case 'webfetch':
        return l10n.autoApproveWebfetchDesc;
      case 'websearch':
        return l10n.autoApproveWebsearchDesc;
      case 'doom_loop':
        return l10n.autoApproveDoomLoopDesc;
      case 'skill':
        return l10n.autoApproveSkillDesc;
      case 'lsp':
        return l10n.autoApproveLspDesc;
      case 'task':
        return l10n.autoApproveTaskDesc;
      case 'external_directory':
        return l10n.autoApproveExternalDirectoryDesc;
      case 'todowrite':
        return l10n.autoApproveTodowriteDesc;
      default:
        return '';
    }
  }

  final AutoApproveState state;
  final AppLocalizations localizations;
  final void Function(
    String categoryId,
    String? defaultAction,
    Map<String, String> exceptions,
  )
  onChanged;

  List<String> _orderedGroups(Map<String, List<AutoApproveCategory>> groups) {
    final ordered = [..._groupOrder];
    for (final g in groups.keys) {
      if (!ordered.contains(g)) ordered.add(g);
    }
    return ordered;
  }

  String _sectionTitle(String group) {
    switch (group) {
      case 'file':
        return localizations.autoApproveGroupFileAccess;
      case 'shell':
        return localizations.autoApproveGroupShell;
      case 'network':
        return localizations.autoApproveGroupNetwork;
      case 'agents':
        return localizations.autoApproveGroupAgents;
      default:
        return '';
    }
  }

  String _inheritLabelFor(String categoryId) {
    final builtin = PermissionRuleset.defaults().rules
        .firstWhere(
          (r) => r.permission == categoryId && r.pattern == '*',
          orElse: () => PermissionRule(
            permission: categoryId,
            pattern: '*',
            action: PermissionAction.ask,
          ),
        )
        .action;

    final actionLabel = switch (builtin) {
      PermissionAction.allow => localizations.defaultAllow,
      PermissionAction.ask => localizations.defaultAsk,
      PermissionAction.deny => localizations.defaultDeny,
    };
    return localizations.autoApproveDefaultInherited(actionLabel);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = <String, List<AutoApproveCategory>>{};

    for (final cat in state.categories) {
      final group = _groupMap[cat.id] ?? 'other';
      groups.putIfAbsent(group, () => []).add(cat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _orderedGroups(groups))
          if (groups.containsKey(group)) ...[
            if (_sectionTitle(group).isNotEmpty)
              Text(
                _sectionTitle(group),
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.lg,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                ),
              ),
            if (_sectionTitle(group).isNotEmpty)
              const SizedBox(height: ChatoraiSpacing.sm),
            ...groups[group]!.asMap().entries.expand(
              (entry) => [
                if (entry.key > 0) const SizedBox(height: ChatoraiSpacing.sm),
                _AutoApproveCategoryTile(
                  key: ValueKey(entry.value.id),
                  category: entry.value,
                  localizations: localizations,
                  inheritLabel: _inheritLabelFor(entry.value.id),
                  onChanged:
                      (
                        String categoryId,
                        String? defaultAction,
                        Map<String, String> exceptions,
                      ) {
                        onChanged(categoryId, defaultAction, exceptions);
                      },
                ),
              ],
            ),
            const SizedBox(height: ChatoraiSpacing.lg),
          ],
      ],
    );
  }
}

class _AutoApproveCategoryTile extends StatefulWidget {
  const _AutoApproveCategoryTile({
    required this.category,
    required this.localizations,
    required this.inheritLabel,
    required this.onChanged,
    super.key,
  });

  final AutoApproveCategory category;
  final AppLocalizations localizations;
  final String inheritLabel;
  final void Function(
    String categoryId,
    String? defaultAction,
    Map<String, String> exceptions,
  )
  onChanged;

  @override
  State<_AutoApproveCategoryTile> createState() =>
      _AutoApproveCategoryTileState();
}

class _AutoApproveCategoryTileState extends State<_AutoApproveCategoryTile> {
  late String? _defaultAction;
  late Map<String, String> _exceptions;

  @override
  void initState() {
    super.initState();
    _defaultAction = widget.category.defaultAction;
    _exceptions = Map<String, String>.from(widget.category.exceptions);
  }

  @override
  void didUpdateWidget(covariant _AutoApproveCategoryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.id != widget.category.id) {
      _defaultAction = widget.category.defaultAction;
      _exceptions = Map<String, String>.from(widget.category.exceptions);
      return;
    }
    if (oldWidget.category.defaultAction != widget.category.defaultAction) {
      _defaultAction = widget.category.defaultAction;
    }
    if (!mapEquals(oldWidget.category.exceptions, widget.category.exceptions)) {
      _exceptions = Map<String, String>.from(widget.category.exceptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final builtin = PermissionRuleset.defaults().rules
        .firstWhere(
          (r) => r.permission == widget.category.id && r.pattern == '*',
          orElse: () => PermissionRule(
            permission: widget.category.id,
            pattern: '*',
            action: PermissionAction.ask,
          ),
        )
        .action;

    final effectiveDefault = _defaultAction ?? builtin.name;
    final isInherit = _defaultAction == null;
    final actionColor = sanitizeActionColor(_defaultAction);
    final showExceptions =
        widget.category.isFileCategory || widget.category.isShellCategory;

    return PremiumCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                AutoApproveCategoryList._iconFor(widget.category.id),
                size: ChatoraiIconSizes.lg,
                color:
                    actionColor ??
                    (isDark
                        ? ChatoraiColors.unselectedItemDark
                        : ChatoraiColors.lightIconColor),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.category.label,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.lg,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ChatoraiColors.pureWhite
                            : ChatoraiColors.pureBlack,
                      ),
                    ),
                    Text(
                      AutoApproveCategoryList._descriptionFor(
                        widget.localizations,
                        widget.category.id,
                      ),
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
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: isInherit ? null : sanitizeAction(effectiveDefault),
                  hint: Text(
                    widget.inheritLabel,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        widget.inheritLabel,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.sm,
                          color: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    ...PermissionAction.values.map((action) {
                      final label = switch (action) {
                        PermissionAction.allow =>
                          widget.localizations.defaultAllow,
                        PermissionAction.ask => widget.localizations.defaultAsk,
                        PermissionAction.deny =>
                          widget.localizations.defaultDeny,
                      };
                      final color = switch (action) {
                        PermissionAction.allow => ChatoraiColors.success,
                        PermissionAction.ask => ChatoraiColors.warning,
                        PermissionAction.deny => ChatoraiColors.error,
                      };
                      return DropdownMenuItem<String?>(
                        value: action.name,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: ChatoraiFontSizes.sm,
                            color: color,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _defaultAction = value;
                    });
                    widget.onChanged(
                      widget.category.id,
                      _defaultAction,
                      _exceptions,
                    );
                  },
                ),
              ),
            ],
          ),
          if (showExceptions) ...[
            Divider(
              height: 1,
              thickness: ChatoraiBorderWidth.thin,
              color: isDark
                  ? ChatoraiColors.darkBorderColor
                  : ChatoraiColors.lightBorderColor,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.localizations.exceptionsTitle,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.sm,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: ChatoraiSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ChatoraiSpacing.sm,
                        vertical: ChatoraiSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? ChatoraiColors.premiumSurfaceRaised
                            : ChatoraiColors.lightSurface,
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.sm,
                        ),
                        border: Border.all(
                          color: isDark
                              ? ChatoraiColors.darkBorderColor
                              : ChatoraiColors.lightBorderColor,
                          width: ChatoraiBorderWidth.thin,
                        ),
                      ),
                      child: Text(
                        '(${_exceptions.length})',
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.xs,
                          color: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddExceptionDialog(context),
                      icon: Icon(Icons.add, size: ChatoraiIconSizes.sm),
                      label: Text(
                        widget.category.isShellCategory
                            ? widget.localizations.addCommand
                            : widget.localizations.addPath,
                        style: const TextStyle(fontSize: ChatoraiFontSizes.sm),
                      ),
                    ),
                  ],
                ),
                if (_exceptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ChatoraiSpacing.sm),
                    child: Text(
                      widget.localizations.autoApproveNoExceptions,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.sm,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                    ),
                  ),
                if (_exceptions.isNotEmpty) ...[
                  const SizedBox(height: ChatoraiSpacing.sm),
                  Wrap(
                    spacing: ChatoraiSpacing.sm,
                    runSpacing: ChatoraiSpacing.sm,
                    children: _exceptions.entries.map((entry) {
                      return _ExceptionChip(
                        pattern: entry.key,
                        action: entry.value,
                        localizations: widget.localizations,
                        isDark: isDark,
                        onActionChanged: (newAction) {
                          setState(() {
                            _exceptions[entry.key] = newAction;
                          });
                          widget.onChanged(
                            widget.category.id,
                            _defaultAction,
                            _exceptions,
                          );
                        },
                        onRemoved: () {
                          setState(() {
                            _exceptions.remove(entry.key);
                          });
                          widget.onChanged(
                            widget.category.id,
                            _defaultAction,
                            _exceptions,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddExceptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AutoApproveRuleDialog(
          category: widget.category,
          localizations: widget.localizations,
          onSave: (pattern, action) {
            setState(() {
              _exceptions[pattern] = action;
            });
            widget.onChanged(widget.category.id, _defaultAction, _exceptions);
          },
        );
      },
    );
  }
}

class _ExceptionChip extends StatelessWidget {
  const _ExceptionChip({
    required this.pattern,
    required this.action,
    required this.localizations,
    required this.isDark,
    required this.onActionChanged,
    required this.onRemoved,
  });

  final String pattern;
  final String action;
  final AppLocalizations localizations;
  final bool isDark;
  final void Function(String action) onActionChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.sm,
        vertical: ChatoraiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? ChatoraiColors.premiumSurfaceRaised
            : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.premiumBorderSoft
              : ChatoraiColors.inputBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pattern,
            style: ChatoraiFontSizes.mono(
              ChatoraiFontSizes.sm,
              color: isDark
                  ? ChatoraiColors.pureWhite
                  : ChatoraiColors.pureBlack,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sanitizeAction(action),
              iconSize: ChatoraiIconSizes.xs,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.xs,
                color:
                    sanitizeActionColor(action) ??
                    (isDark
                        ? ChatoraiColors.darkTextColor
                        : ChatoraiColors.lightTextColor),
              ),
              items: PermissionAction.values.map((action) {
                final label = switch (action) {
                  PermissionAction.allow => localizations.defaultAllow,
                  PermissionAction.ask => localizations.defaultAsk,
                  PermissionAction.deny => localizations.defaultDeny,
                };
                return DropdownMenuItem<String>(
                  value: action.name,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (newAction) {
                if (newAction == null) return;
                onActionChanged(newAction);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: ChatoraiIconSizes.sm),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: ChatoraiSizes.iconButtonSplashRadius,
              minHeight: ChatoraiSizes.iconButtonSplashRadius,
            ),
            onPressed: onRemoved,
          ),
        ],
      ),
    );
  }
}
