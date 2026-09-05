import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/sessions/presentation/widgets/sidebar_wrapper.dart';
import 'package:chatorai/providers.dart' show chatListProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatSidebarDrawer extends ConsumerStatefulWidget {
  final double width;
  final VoidCallback onToggleSidebar;
  final void Function(String) onChatSelect;
  final void Function(String) onChatDelete;
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;

  /// Stable cache key for the rendered drawer. Includes the chat title so a
  /// rename invalidates the cached [Drawer] (previously only ids were hashed,
  /// leaving a stale title on screen after `renameChat`).
  static String chatListHash(List<Chat> chats) =>
      chats.fold<String>('', (hash, chat) => '$hash${chat.id}:${chat.title}');

  const ChatSidebarDrawer({
    super.key,
    required this.width,
    required this.onToggleSidebar,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
    required this.onOpenSettings,
  });

  @override
  ConsumerState<ChatSidebarDrawer> createState() => _ChatSidebarDrawerState();
}

class _ChatSidebarDrawerState extends ConsumerState<ChatSidebarDrawer> {
  Widget? _cachedSidebarDrawer;
  double _cachedDrawerWidth = 0;
  String? _cachedChatListHash;

  @override
  Widget build(BuildContext context) {
    final chatListState = ref.watch(chatListProvider);
    final chatListHash = chatListState.when(
      data: (chats) => ChatSidebarDrawer.chatListHash(chats),
      loading: () => 'loading',
      error: (e, st) => 'error',
    );

    if (_cachedSidebarDrawer == null ||
        _cachedDrawerWidth != widget.width ||
        _cachedChatListHash != chatListHash) {
      _cachedDrawerWidth = widget.width;
      _cachedChatListHash = chatListHash;
      _cachedSidebarDrawer = Drawer(
        width: widget.width,
        child: SidebarWrapper(
          width: widget.width,
          onToggleSidebar: widget.onToggleSidebar,
          onChatSelect: widget.onChatSelect,
          onChatDelete: widget.onChatDelete,
          onNewChat: widget.onNewChat,
          onOpenSettings: widget.onOpenSettings,
        ),
      );
    }
    return _cachedSidebarDrawer!;
  }
}
