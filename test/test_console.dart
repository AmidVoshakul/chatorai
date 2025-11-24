import 'dart:io';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';

void main() async {
  print('🧪 Testing message deletion functionality...');
  
  try {
    final chatStorageService = ChatStorageService();
    print('✅ ChatStorageService initialized');
    
    // Create a test chat
    final testChat = Chat(
      id: 'test-chat-console',
      title: 'Test Chat Console',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    await chatStorageService.addChat(testChat);
    print('✅ Test chat created');

    // Add a test message
    final testMessage = Message(
      id: 'test-msg-console',
      content: 'Test message content from console',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    await chatStorageService.addMessageToChat(testChat.id, testMessage);
    print('✅ Test message added');

    // Verify message exists
    final chatWithMessage = await chatStorageService.getChat(testChat.id);
    print('📊 Chat has ${chatWithMessage?.messages.length ?? 0} messages');
    
    if (chatWithMessage?.messages.length == 1) {
      print('✅ Message exists in chat');
      
      // Delete the message
      await chatStorageService.deleteMessageFromChat(testChat.id, testMessage.id);
      print('🗑️ Message deleted from chat');
      
      // Verify message is deleted
      final chatAfterDeletion = await chatStorageService.getChat(testChat.id);
      print('📊 Chat has ${chatAfterDeletion?.messages.length ?? 0} messages after deletion');
      
      if (chatAfterDeletion?.messages.length == 0) {
        print('✅ Message deletion successful!');
      } else {
        print('❌ Message deletion failed');
      }
    } else {
      print('❌ Message was not added correctly');
    }
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
  
  print('🏁 Test completed');
  exit(0);
}