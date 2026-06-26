import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SkillsPopup extends StatefulWidget {
  final List<SkillInfo> skills;
  final Set<String> allowedSkillNames;
  final int selectedIndex;
  final ValueChanged<SkillInfo> onSelected;
  final String filter;
  final VoidCallback? onClose;
  final bool isLoading;
  final ScrollController? scrollController;

  const SkillsPopup({
    super.key,
    required this.skills,
    this.allowedSkillNames = const {},
    required this.selectedIndex,
    required this.onSelected,
    this.filter = '',
    this.onClose,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  State<SkillsPopup> createState() => _SkillsPopupState();
}

class _SkillsPopupState extends State<SkillsPopup> {
  static const double _kItemHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant SkillsPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final offset = widget.selectedIndex * _kItemHeight;
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final query = widget.filter.toLowerCase();
    final filtered = query.isEmpty
        ? widget.skills
        : widget.skills
              .where(
                (s) =>
                    s.name.toLowerCase().contains(query) ||
                    s.description.toLowerCase().contains(query),
              )
              .toList();

    String? emptyMessage;
    if (widget.isLoading) {
      emptyMessage = localizations.loadingSkills;
    } else if (widget.skills.isEmpty) {
      emptyMessage = localizations.noSkillsInstalled;
    } else if (filtered.isEmpty && widget.filter.isNotEmpty) {
      emptyMessage = localizations.noSkillsMatchSearch;
    } else if (filtered.isEmpty) {
      emptyMessage = localizations.allSkillsRequirePermission;
    }

    if (emptyMessage != null) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(_ThemeDefaults.borderRadius),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(_ThemeDefaults.spacingLg),
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(_ThemeDefaults.borderRadius),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_ThemeDefaults.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  tooltip: localizations.close,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemExtent: _kItemHeight,
                itemBuilder: (context, index) {
                  final skill = filtered[index];
                  final isAllowed = widget.allowedSkillNames.contains(
                    skill.name,
                  );
                  final isSelected = index == widget.selectedIndex;
                  return InkWell(
                    onTap: () => widget.onSelected(skill),
                    child: Opacity(
                      opacity: isAllowed ? 1.0 : 0.5,
                      child: Container(
                        height: _kItemHeight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _ThemeDefaults.spacingLg,
                          vertical: _ThemeDefaults.spacingSm,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: _ThemeDefaults.iconSize,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.primary,
                            ),
                            if (!isAllowed) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.lock,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                            ],
                            const SizedBox(width: _ThemeDefaults.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    skill.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    skill.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeDefaults {
  static const double borderRadius = 8.0;
  static const double iconSize = 20.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
}
