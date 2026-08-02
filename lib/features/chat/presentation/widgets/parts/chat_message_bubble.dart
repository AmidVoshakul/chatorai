import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/bubbles/assistant_bubble.dart';
import 'package:chatorai/features/chat/presentation/widgets/bubbles/system_bubble.dart';
import 'package:chatorai/features/chat/presentation/widgets/bubbles/user_bubble.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/error_message_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/user_message_edit.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String chatId;
  final String messageId;
  final SessionRepository sessionRepository;
  final String? agentName;
  final Future<void> Function(String)? onContinuationSelected;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Function(String, String)? onMessageEdited;
  final Function(String, String)? onMessageEditedAndSend;
  final bool isLastMessage;
  final Function(String messageId, String answer)? onQuestionAnswer;
  final int? cumulativeTokens;
  final int? contextLength;
  final void Function(String? sessionId)? onTaskTap;
  final bool expandReasoningByDefault;
  final bool reasoningEnabled;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    required this.sessionRepository,
    this.agentName,
    this.onContinuationSelected,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onMessageEdited,
    this.onMessageEditedAndSend,
    this.isLastMessage = false,
    this.onQuestionAnswer,
    this.cumulativeTokens,
    this.contextLength,
    this.onTaskTap,
    this.expandReasoningByDefault = true,
    this.reasoningEnabled = true,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = _getMessageContent();
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _textController.text = _getMessageContent();
    });
  }

  Future<void> _saveEditing() async {
    final newContent = _textController.text.trim();
    if (newContent.isNotEmpty && newContent != _getMessageContent()) {
      widget.onMessageEdited?.call(widget.messageId, newContent);
    }
    setState(() => _isEditing = false);
  }

  Future<void> _saveAndSend() async {
    final newContent = _textController.text.trim();
    if (newContent.isNotEmpty) {
      widget.onMessageEditedAndSend?.call(widget.messageId, newContent);
    }
    setState(() => _isEditing = false);
  }

  String _getMessageContent() {
    return switch (widget.message) {
      UserMessage m => m.content,
      AssistantMessage m =>
        m.parts.whereType<TextPart>().map((p) => p.content).join('\n'),
      SystemMessage m => m.content,
      ErrorMessage m => m.content,
      ChatMessage() => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && widget.message is UserMessage) {
      return UserMessageEdit(
        controller: _textController,
        onCancel: _cancelEditing,
        onSave: _saveEditing,
        onSaveAndSend: _saveAndSend,
        content: _getMessageContent(),
        chatId: widget.chatId,
        messageId: widget.messageId,
        sessionRepository: widget.sessionRepository,
        onMessageDeleted: widget.onMessageDeleted,
        onMessageRegenerate: widget.onMessageRegenerate,
        onContinuationSelected: widget.onContinuationSelected,
        cumulativeTokens: widget.cumulativeTokens,
        contextLength: widget.contextLength,
      );
    }
    return switch (widget.message) {
      UserMessage m => UserMessageBubble(
        message: m,
        chatId: widget.chatId,
        messageId: widget.messageId,
        sessionRepository: widget.sessionRepository,
        onEdit: _startEditing,
        onMessageDeleted: widget.onMessageDeleted,
        onMessageRegenerate: widget.onMessageRegenerate,
        onContinuationSelected: widget.onContinuationSelected,
        cumulativeTokens: widget.cumulativeTokens,
        contextLength: widget.contextLength,
        timestamp: m.timestamp,
      ),
      AssistantMessage m => AssistantMessageBubble(
        message: m,
        chatId: widget.chatId,
        messageId: widget.messageId,
        agentName: widget.agentName,
        isLastMessage: widget.isLastMessage,
        onContinuationSelected: widget.onContinuationSelected,
        onMessageDeleted: widget.onMessageDeleted,
        onMessageRegenerate: widget.onMessageRegenerate,
        cumulativeTokens: widget.cumulativeTokens,
        contextLength: widget.contextLength,
        expandReasoningByDefault: widget.expandReasoningByDefault,
        reasoningEnabled: widget.reasoningEnabled,
        onTaskTap: widget.onTaskTap,
        sessionRepository: widget.sessionRepository,
      ),
      SystemMessage m => SystemMessageBubble(message: m),
      ErrorMessage m => _errorBubble(m, context),
      ChatMessage() => const SizedBox.shrink(),
    };
  }

  Widget _errorBubble(ErrorMessage m, BuildContext context) {
    return ErrorMessageBubble(
      errorMessage: m.content,
      onCopy: () {
        Clipboard.setData(ClipboardData(text: m.content));
        if (mounted) {
          SnackbarUtils.showSuccessSnackBar(
            context: context,
            message: AppLocalizations.of(context)!.messageCopied,
            icon: Icons.copy,
            duration: const Duration(seconds: 1),
          );
        }
      },
      onRegenerate: widget.onMessageRegenerate,
      onDelete: widget.onMessageDeleted,
    );
  }
}
