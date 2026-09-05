import 'package:chatorai/core/commands/slash_command.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CommandPopup extends StatefulWidget {
  final List<SlashCommand> commands;
  final int selectedIndex;
  final ValueChanged<SlashCommand> onSelected;
  final String filter;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const CommandPopup({
    super.key,
    required this.commands,
    required this.selectedIndex,
    required this.onSelected,
    this.filter = '',
    this.onClose,
    this.scrollController,
  });

  @override
  State<CommandPopup> createState() => _CommandPopupState();
}

class _CommandPopupState extends State<CommandPopup> {
  static const double _kItemHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant CommandPopup oldWidget) {
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
    // Commands are already filtered by the handler via SlashCommandCatalog.filter;
    // popup just displays them to keep business logic in core.
    final filtered = widget.commands;

    if (filtered.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(16),
          child: Text(
            'No commands match your search',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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
                  final cmd = filtered[index];
                  final selected = index == widget.selectedIndex;
                  return InkWell(
                    onTap: () => widget.onSelected(cmd),
                    child: Container(
                      height: _kItemHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: selected
                          ? PopupItemDefaults.selectedItemDecoration(context)
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.code,
                            size: 20,
                            color: selected
                                ? PopupItemDefaults.selectedIconColor(context)
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cmd.name,
                                  style: selected
                                      ? PopupItemDefaults.selectedNameStyle(
                                          context,
                                        )
                                      : theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                Text(
                                  cmd.description.isEmpty &&
                                          cmd.hints.isNotEmpty
                                      ? cmd.hints.join('  ')
                                      : cmd.description,
                                  style: selected
                                      ? PopupItemDefaults.selectedDescriptionStyle(
                                          context,
                                        )
                                      : theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .textTheme
                                              .bodySmall
                                              ?.color
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
