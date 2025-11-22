import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/screens/settings_screen.dart';

class SidebarFooter extends StatelessWidget {
  final bool isCollapsed;

  const SidebarFooter({
    Key? key,
    required this.isCollapsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
            color: theme.iconTheme.color,
            hoverColor: theme.colorScheme.primary.withOpacity(0.1),
          ),
          
          const SizedBox(width: 8),
          
          // Profile Icon
          if (!isCollapsed)
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    // TODO: Open profile
                  },
                  borderRadius: BorderRadius.circular(20),
                  hoverColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // User Avatar
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Free Plan',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Dropdown Icon
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: theme.iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}