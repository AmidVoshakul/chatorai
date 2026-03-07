import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/chat_screen_notifier.dart';
import 'package:chatorai/providers/chat/chat_providers.dart';

final chatScreenProvider =
    StateNotifierProvider<ChatScreenNotifier, ChatScreenState>((ref) {
      final storageService = ref.read(chatStorageServiceProvider);
      return ChatScreenNotifier(storageService);
    });
