import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';

class Sidebar extends StatelessWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleSidebar;

  const Sidebar({
    Key? key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleSidebar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();

    return AnimatedContainer(
      width: isCollapsed ? 80 : width,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (!isCollapsed)
                  Flexible(
                    child: Text(
                      'GenUI',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.headlineSmall?.color,
                        fontSize: 18, // Reduced font size for better fit
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (isCollapsed) const SizedBox(width: 4), // Small spacer for collapsed state
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu_open : Icons.menu,
                    color: theme.iconTheme.color,
                    size: 20, // Reduced icon size
                  ),
                  onPressed: onToggleSidebar,
                  padding: EdgeInsets.zero, // Remove default padding
                ),
              ],
            ),
          ),
          
          // Main Content Area (Scrollable)
          Expanded(
            child: Column(
              children: [
                // New Chat Button
                ListTile(
                  leading: const Icon(Icons.add),
                  title: !isCollapsed ? const Text('New Chat') : null,
                  onTap: () {
                    // TODO: Create new chat
                  },
                ),
                
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor,
                ),
                
                if (!isCollapsed) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.dividerColor,
                  ),
                  
                  // Recent Chats Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Recent Chats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  

                ],
              ],
            ),
          ),
          
          // Footer
          Column(
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor,
              ),
              // Settings
              ListTile(
                leading: const Icon(Icons.settings),
                title: !isCollapsed ? const Text('Settings') : null,
                onTap: () {
                  // TODO: Open settings
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}