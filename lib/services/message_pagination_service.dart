import 'package:chatorai/models/chat_models.dart';
import '../utils/logger.dart';

// Initialize logger for this service
final _logger = LogTags.pagination;

class MessagePaginationService {
  static const int pageSize = 20;
  
  Future<List<Message>> loadMessages({
    required String conversationId,
    int page = 0,
    String? beforeTimestamp,
    String? afterTimestamp,
  }) async {
    // Simulate API call with pagination
    await Future.delayed(const Duration(milliseconds: 500));
    _logger.logDebug('Loading messages for conversation: $conversationId, page: $page');
    
    // Generate mock messages for pagination
    final messages = <Message>[];
    final baseTime = DateTime.now();
    
    for (int i = 0; i < pageSize; i++) {
      final messageTime = beforeTimestamp != null 
          ? baseTime.subtract(Duration(hours: page * pageSize + i))
          : baseTime.add(Duration(hours: page * pageSize + i));
          
      messages.add(
        Message(
          id: 'msg_${conversationId}_${page}_${i}',
          role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
          content: _generateMockContent(i),
          timestamp: messageTime,
          isComplete: true,
        ),
      );
    }
    
    return messages;
  }
  
  Future<bool> hasMoreMessages({
    required String conversationId,
    String? beforeTimestamp,
  }) async {
    // Simulate checking if more messages exist
    await Future.delayed(const Duration(milliseconds: 200));
    _logger.logDebug('Checking if more messages exist for conversation: $conversationId');
    
    // For demo purposes, return true for first few pages
    return beforeTimestamp != null && !beforeTimestamp.contains('page_0');
  }
  
  String _generateMockContent(int index) {
    final contents = [
      'Hello! How can I assist you today?',
      'I can help you with various tasks including coding, writing, and problem-solving.',
      'Let me know what you need help with!',
      'Here\'s a comprehensive solution to your problem...',
      'Would you like me to elaborate on this topic?',
      'I understand your concern. Let me provide a detailed explanation.',
      'Based on your requirements, here\'s my recommendation:',
      'This is an interesting question. Let me think about it.',
      'I can see you\'re working on an important project.',
      'Let\'s break this down into manageable steps.',
    ];
    
    return contents[index % contents.length];
  }
  
  // Load initial messages for a conversation
  Future<List<Message>> loadInitialMessages(String conversationId) async {
    return await loadMessages(conversationId: conversationId, page: 0);
  }
  
  // Load older messages (pagination)
  Future<List<Message>> loadOlderMessages({
    required String conversationId,
    required DateTime beforeTimestamp,
  }) async {
    return await loadMessages(
      conversationId: conversationId,
      beforeTimestamp: beforeTimestamp.toIso8601String(),
    );
  }
  
  // Load newer messages (for real-time updates)
  Future<List<Message>> loadNewerMessages({
    required String conversationId,
    required DateTime afterTimestamp,
  }) async {
    return await loadMessages(
      conversationId: conversationId,
      afterTimestamp: afterTimestamp.toIso8601String(),
    );
  }
}