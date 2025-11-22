import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/widgets/sidebar/sidebar.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_input.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_messages.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  final double _sidebarWidth = 280;
  final double _sidebarCollapsedWidth = 80;

  void _handleSendMessage(String message) {
    // Handle sending message
    print('Sending message: $message');
  }

  void _handleToggleStreaming(bool isStreaming) {
    // Handle toggling streaming
    print('Streaming toggled: $isStreaming');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Simple mobile/desktop detection
    final isMobile = screenWidth < 800;

    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GenUI',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.canvasColor,
        elevation: 0,
        actions: [],
      ),
      drawer: Drawer(
        child: Sidebar(
          width: _sidebarWidth,
          isCollapsed: false,
          onToggleSidebar: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessages(),
          ),
          ChatInput(
            onSendMessage: _handleSendMessage,
            onToggleStreaming: _handleToggleStreaming,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            width: _isSidebarCollapsed ? _sidebarCollapsedWidth : _sidebarWidth,
            isCollapsed: _isSidebarCollapsed,
            onToggleSidebar: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      
                      // Theme Toggle
                      IconButton(
                        icon: Icon(
                          theme.brightness == Brightness.dark
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                        ),
                        onPressed: () {
                          final themeProvider =
                              Provider.of<ThemeProvider>(context, listen: false);
                          themeProvider.isDarkMode = !themeProvider.isDarkMode;
                        },
                      ),
                    ],
                  ),
                ),
                
                // Chat Messages
                Expanded(
                  child: ChatMessages(),
                ),
                
                // Input Area
                ChatInput(
                  onSendMessage: _handleSendMessage,
                  onToggleStreaming: _handleToggleStreaming,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
