import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AgentMentionPopup extends StatelessWidget {
  final List<AgentDefinition> agents;
  final int selectedIndex;
  final ValueChanged<AgentDefinition> onSelected;
  final VoidCallback? onClose;

  const AgentMentionPopup({
    super.key,
    required this.agents,
    required this.selectedIndex,
    required this.onSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: 340),
          padding: const EdgeInsets.all(16),
          child: Text(
            'No agents available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final popupContent = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  tooltip: 'Close',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: agents.length,
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  final isSelected = index == selectedIndex;
                  return InkWell(
                    onTap: () => onSelected(agent),
                    child: Container(
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
                              mainAxisSize: MainAxisSize.min,
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

    return Stack(
      children: [
        // Clickable barrier that closes popup when tapped
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
          ),
        ),
        // The popup itself
        Positioned(
          bottom: 0, // Will be positioned by parent
          left: 0,
          right: 0,
          child: popupContent,
        ),
      ],
    );
  }
}
