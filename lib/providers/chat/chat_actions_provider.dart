import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.sidebar;

class ChatActionsNotifier extends StateNotifier<void> {
  final Chat chat;
  final VoidCallback onDelete;

  ChatActionsNotifier(this.chat, this.onDelete) : super(null);

  Future<void> handleCopyChat(BuildContext context) async {
    try {
      await MessageUtils.copyChat(
        messages: chat.messages,
        chatTitle: chat.title,
        context: context,
      );
    } catch (e, stackTrace) {
      _logger.logError(
        '[ChatActionsNotifier] Failed to copy chat: $e\nStack trace: $stackTrace',
      );
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Failed to copy chat',
        icon: Icons.error,
      );
    }
  }

  Future<String?> showRenameDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: chat.title,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new chat name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLength: 50,
          maxLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    return result;
  }

  void handleDelete() {
    onDelete();
  }
}

final chatActionsProvider = StateNotifierProvider.autoDispose
    .family<ChatActionsNotifier, void, ChatActionsParams>(
      (ref, params) => ChatActionsNotifier(params.chat, params.onDelete),
    );

class ChatActionsParams {
  final Chat chat;
  final VoidCallback onDelete;

  ChatActionsParams({required this.chat, required this.onDelete});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatActionsParams &&
        other.chat.id == chat.id &&
        other.onDelete == onDelete;
  }

  @override
  int get hashCode => Object.hash(chat.id, onDelete);
}
