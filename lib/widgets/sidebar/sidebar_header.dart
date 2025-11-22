import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleSidebar;

  const SidebarHeader({
    Key? key,
    required this.isCollapsed,
    required this.onToggleSidebar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.getTheme();
    
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Logo/Icon
          Icon(
            Icons.chat,
            color: Colors.white,
            size: isCollapsed ? 24 : 28,
          ),
          
          const SizedBox(width: 12),
          
          // Title
          if (!isCollapsed)
            Expanded(
              child: Text(
                'GenUI Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          const Spacer(),
          
          // Collapse/Expand Button
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu_open : Icons.menu,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onToggleSidebar,
            tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }
}