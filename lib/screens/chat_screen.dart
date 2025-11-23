import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/widgets/sidebar/sidebar.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_input.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_messages.dart';
import 'package:gen_ui_chat_ai/screens/models_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late OpenRouterService _openRouterService;
  late ThemeProvider _themeProvider;
  
  bool _isSidebarCollapsed = false;
  final double _sidebarWidth = 280;
  final double _sidebarCollapsedWidth = 40;
  
  List<Chat> _chats = [];
  Chat? _currentChat;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatStorageService = ChatStorageService();
    _openRouterService = OpenRouterService();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadChats();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatStorageService.getChats();
      setState(() {
        _chats = chats;
        if (_chats.isNotEmpty && _currentChat == null) {
          _selectChat(_chats.first.id);
        }
      });
    } catch (e) {
      print('Error loading chats: $e');
    }
  }

  Future<void> _createNewChat() async {
    final newChat = _chatStorageService.newChat();
    await _chatStorageService.addChat(newChat);
    await _loadChats();
    _selectChat(newChat.id);
    
    if (MediaQuery.of(context).size.width < 800) {
      setState(() => _isSidebarCollapsed = true);
    }
  }

  void _selectChat(String chatId) {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    setState(() {
      _currentChat = chat;
    });
  }

  Future<void> _deleteChat(String chatId) async {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    final String currentLanguage = _themeProvider.selectedLanguage;
    
    String getLocalizedText(String key) {
      if (currentLanguage == 'en') {
        return {
          'deleteChat': 'Delete Chat',
          'confirmDelete': 'Are you sure you want to delete the chat "${chat.title}"?',
          'cancel': 'Cancel',
          'delete': 'Delete',
        }[key] ?? key;
      } else {
        return {
          'deleteChat': 'Удалить чат',
          'confirmDelete': 'Вы действительно хотите удалить чат "${chat.title}"?',
          'cancel': 'Отмена',
          'delete': 'Удалить',
        }[key] ?? key;
      }
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getLocalizedText('deleteChat')),
        content: Text(getLocalizedText('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(getLocalizedText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(getLocalizedText('delete')),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _chatStorageService.deleteChat(chatId);
      await _loadChats();
      
      if (_currentChat?.id == chatId) {
        if (_chats.isNotEmpty) {
          _selectChat(_chats.first.id);
        } else {
          setState(() {
            _currentChat = null;
          });
        }
      }
    }
  }

  void _handleSendMessage(String message) async {
    if (_currentChat == null) {
      await _createNewChat();
      if (_currentChat == null) return;
    }

    final userMessage = Message(
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now(),
    );

    // Add user message to chat
    await _chatStorageService.addMessageToChat(_currentChat!.id, userMessage);
    
    // Update local state
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, userMessage],
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentChat = updatedChat;
    });

    // TODO: Send to AI and handle response
    print('Sending message: $message');
  }

  void _handleToggleStreaming(bool isStreaming) {
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
        actions: [
          
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ModelsScreen()),
                );
              },
              tooltip: 'Navigate to Models',
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Sidebar(
          width: _sidebarWidth,
          isCollapsed: false,
          onToggleSidebar: () {
            Navigator.pop(context);
          },
          chats: _chats,
          currentChat: _currentChat,
          onChatSelect: _selectChat,
          onChatDelete: _deleteChat,
          onNewChat: _createNewChat,
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
            chats: _chats,
            currentChat: _currentChat,
            onChatSelect: _selectChat,
            onChatDelete: _deleteChat,
            onNewChat: _createNewChat,
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

                      IconButton(
                        icon: const Icon(Icons.smart_toy),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ModelsScreen()),
                          );
                        },
                        tooltip: 'Navigate to Models',
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
