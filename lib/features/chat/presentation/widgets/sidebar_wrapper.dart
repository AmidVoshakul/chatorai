import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart' show chatScreenProvider;
import 'package:chatorai/features/chat/presentation/widgets/sidebar.dart';

class SidebarWrapper extends ConsumerStatefulWidget {
  final double width;
  final VoidCallback onToggleSidebar;
  final Function(String) onChatSelect;
  final Function(String) onChatDelete;
  final Function() onNewChat;

  const SidebarWrapper({
    super.key,
    required this.width,
    required this.onToggleSidebar,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
  });

  @override
  ConsumerState<SidebarWrapper> createState() => _SidebarWrapperState();
}

class _SidebarWrapperState extends ConsumerState<SidebarWrapper> {
  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(
      chatScreenProvider.select((s) => s.isSidebarCollapsed),
    );

    return Sidebar(
      width: widget.width,
      isCollapsed: isCollapsed,
      onToggleSidebar: widget.onToggleSidebar,
      onChatSelect: widget.onChatSelect,
      onChatDelete: widget.onChatDelete,
      onNewChat: widget.onNewChat,
    );
  }
}
