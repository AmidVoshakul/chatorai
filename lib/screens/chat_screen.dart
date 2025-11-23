// ignore_for_file: avoid_print

import 'dart:math';
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
  final String? initialModel;

  const ChatScreen({
    Key? key,
    this.initialModel,
  }) : super(key: key);

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
  String _selectedModel = 'x-ai/grok-4.1-fast:free'; // Default model

  @override
  void initState() {
    super.initState();
    print('[ChatScreen] 🔧 Initializing ChatScreen services...');
    _chatStorageService = ChatStorageService();
    print('[ChatScreen] ✅ ChatStorageService initialized');
    _openRouterService = OpenRouterService();
    print('[ChatScreen] ✅ OpenRouterService initialized');
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // Initialize selected model from widget parameter or use default
    if (widget.initialModel != null) {
      _selectedModel = widget.initialModel!;
      print('[ChatScreen] ✅ Using initial model: $_selectedModel');
    } else {
      print('[ChatScreen] ✅ Using default model: $_selectedModel');
    }
    
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
    print('[ChatScreen] 📤 Received message to send: $message');
    if (_currentChat == null) {
      print('[ChatScreen] 🆕 Creating new chat...');
      await _createNewChat();
      if (_currentChat == null) {
        print('[ChatScreen] ❌ Failed to create chat');
        return;
      }
      print('[ChatScreen] ✅ New chat created: ${_currentChat!.id}');
    } else {
      print('[ChatScreen] 📝 Using existing chat: ${_currentChat!.id}');
    }

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now(),
      isComplete: true,
    );

    print('[ChatScreen] 📝 Created user message: ${userMessage.id}');
    
    // Add user message to chat storage
    await _chatStorageService.addMessageToChat(_currentChat!.id, userMessage);
    print('[ChatScreen] 💾 Message saved to storage');
    
    // Update local state immediately
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, userMessage],
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentChat = updatedChat;
    });

    // Send message to AI and handle streaming response
    _sendToAI(message);
  }

  Future<void> _sendToAI(String userMessage) async {
    print('[ChatScreen] 📤 Starting _sendToAI with message: $userMessage');
    if (_currentChat == null) {
      print('[ChatScreen] ❌ No current chat available in _sendToAI');
      return;
    }
    print('[ChatScreen] ✅ Current chat available, proceeding with AI processing');

    try {
      // Add assistant message placeholder
      final assistantMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
        model: _selectedModel,
      );

      // Update chat storage and local state immediately
      await _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
      
      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, assistantMessage],
        updatedAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _currentChat = updatedChat;
        });
      }

      // Stream response from AI
      print('[ChatScreen] 📤 Starting AI response streaming after message saved');
      await _streamAIResponse();
      print('[ChatScreen] ✅ AI response streaming completed');
    } catch (e) {
      print('Error sending message to AI: $e');
      
      // Add error message
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: 'Sorry, I encountered an error while processing your request. Please try again.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await _chatStorageService.addMessageToChat(_currentChat!.id, errorMessage);
      
      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, errorMessage],
        updatedAt: DateTime.now(),
      );
      setState(() {
        _currentChat = updatedChat;
      });
    }
  }

  Future<void> _streamAIResponse() async {
    print('[ChatScreen] 🚀 Starting AI response streaming...');
    if (_currentChat == null) {
      print('[ChatScreen] ❌ No current chat available');
      return;
    }
    print('[ChatScreen] ✅ Current chat available, proceeding...');

    try {
      final messages = _currentChat!.messages
          .map((msg) => {
            'role': msg.role.name,
            'content': msg.content
          })
          .toList();
      
      print('[ChatScreen] 📝 Sending ${messages.length} messages to AI service');
      print('[ChatScreen] 📝 Messages: ${messages.map((m) => '${m['role']}: ${m['content']}').join(' | ')}');

      // Use a working OpenRouter model
      final selectedModel = _selectedModel;
      print('[ChatScreen] 🎯 Using model: $selectedModel');
      
      await _openRouterService.streamChatCompletion(
        messages: messages,
        model: selectedModel,
        onChunk: (content) {
          final displayLength = min(50, content.length);
          print('[ChatScreen] 🌊 Received chunk: ${content.substring(0, displayLength)}...');
          if (content.isNotEmpty) {
            // Update the last message with new content
            final lastMessage = _currentChat!.messages.last;
            final updatedMessage = lastMessage.copyWith(content: lastMessage.content + content);
            
            print('[ChatScreen] ✏️ Updating message ${updatedMessage.id} with content length: ${updatedMessage.content.length}');
            
            _chatStorageService.updateMessageInChat(
              _currentChat!.id, 
              updatedMessage.id, 
              updatedMessage
            ).then((_) {
              print('[ChatScreen] ✅ Message updated in storage');
              final updatedChat = _currentChat!.copyWith(
                messages: [
                  ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
                  updatedMessage
                ],
                updatedAt: DateTime.now(),
              );
              
              if (mounted) {
                setState(() {
                  _currentChat = updatedChat;
                });
              }
            });
          }
        },
        onCompletion: (fullContent) {
          // Mark message as complete
          final lastMessage = _currentChat!.messages.last;
          final completedMessage = lastMessage.copyWith(isComplete: true);
          
          _chatStorageService.updateMessageInChat(
            _currentChat!.id, 
            completedMessage.id, 
            completedMessage
          ).then((_) {
            final updatedChat = _currentChat!.copyWith(
              messages: [
                ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
                completedMessage
              ],
              updatedAt: DateTime.now(),
            );
            
            if (mounted) {
              setState(() {
                _currentChat = updatedChat;
              });
            }
          });
        },
      );
    } catch (e) {
      print('Error in streaming response: $e');
      
      // Add error message
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: 'I apologize, but I encountered an error while generating the response. Please try again.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await _chatStorageService.addMessageToChat(_currentChat!.id, errorMessage);
      
      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, errorMessage],
        updatedAt: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _currentChat = updatedChat;
        });
      }
    }
  }

  // Method to add assistant message from ChatMessages
  void addAssistantMessage() {
    if (_currentChat == null) return;

    final assistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
    );

    // Update chat storage and local state immediately
    _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
    
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    if (mounted) {
      setState(() {
        _currentChat = updatedChat;
      });
    }
  }

  // Method to update assistant message content
  void updateAssistantMessage(String content) {
    if (_currentChat == null) return;

    final messages = _currentChat!.messages;
    if (messages.isNotEmpty && messages.last.role == MessageRole.assistant) {
      final updatedMessage = messages.last.copyWith(content: content);
      
      _chatStorageService.updateMessageInChat(
        _currentChat!.id, 
        updatedMessage.id, 
        updatedMessage
      ).then((_) {
        final updatedChat = _currentChat!.copyWith(
          messages: [
            ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
            updatedMessage
          ],
          updatedAt: DateTime.now(),
        );
        
        if (mounted) {
          setState(() {
            _currentChat = updatedChat;
          });
        }
      });
    }
  }

  void _handleToggleStreaming(bool isStreaming) {
    print('Streaming toggled: $isStreaming');
  }

  @override
  Widget build(BuildContext context) {
    print('[ChatScreen] 🏗️ Building ChatScreen, current chat: ${_currentChat?.id}, messages: ${_currentChat?.messages.length ?? 0}');
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
                  MaterialPageRoute(
                    builder: (context) => ModelsScreen(
                      onModelSelected: (String modelId) {
                        setState(() {
                          _selectedModel = modelId;
                        });
                        Navigator.pop(context);
                      },
                      currentModel: _selectedModel,
                    ),
                  ),
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
            child: ChatMessages(
              openRouterService: _openRouterService,
              chat: _currentChat,
              selectedModel: _selectedModel,
              onSendMessage: _handleSendMessage,
            ),
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
                            MaterialPageRoute(
                              builder: (context) => ModelsScreen(
                                onModelSelected: (String modelId) {
                                  setState(() {
                                    _selectedModel = modelId;
                                  });
                                  Navigator.pop(context);
                                },
                                currentModel: _selectedModel,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Navigate to Models',
                      ),
                    ],
                  ),
                ),
                
                // Chat Messages
                Expanded(
                  child: ChatMessages(
                    openRouterService: _openRouterService,
                    chat: _currentChat,
                    selectedModel: _selectedModel,
                    onSendMessage: _handleSendMessage,
                  ),
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
