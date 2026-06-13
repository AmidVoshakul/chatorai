import 'package:flutter/material.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class AgentMentionPopup extends StatefulWidget {
  final List<AgentDefinition> agents;
  final int selectedIndex;
  final ValueChanged<AgentDefinition> onSelected;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const AgentMentionPopup({
    super.key,
    required this.agents,
    required this.selectedIndex,
    required this.onSelected,
    this.onClose,
    this.scrollController,
  });

  @override
  State<AgentMentionPopup> createState() => _AgentMentionPopupState();
}

class _AgentMentionPopupState extends State<AgentMentionPopup> {
  static const double _kItemHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant AgentMentionPopup oldWidget) {
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
    if (widget.agents.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(16),
          child: Text(
            'No agents available',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
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
                  tooltip: 'Close',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: widget.agents.length,
                itemExtent: _kItemHeight,
                itemBuilder: (context, index) {
                  final agent = widget.agents[index];
                  final isSelected = index == widget.selectedIndex;
                  return InkWell(
                    onTap: () => widget.onSelected(agent),
                    child: Container(
                      height: _kItemHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ChatoraiSpacing.lg,
                        vertical: ChatoraiSpacing.sm,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: ChatoraiIconSizes.buttonIcon,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: ChatoraiSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  agent.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (agent.description != null)
                                  Text(
                                    agent.description!,
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
                          const SizedBox(width: ChatoraiSpacing.sm),
                          Text(
                            '@${agent.id}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontFamily: 'monospace',
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
