import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/chat_screen_notifier.dart';

final chatScreenProvider =
    StateNotifierProvider<ChatScreenNotifier, ChatScreenState>((ref) {
      return ChatScreenNotifier();
    });
