import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool) onToggleStreaming;
  final FocusNode? focusNode;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    required this.onToggleStreaming,
    this.focusNode,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startSpeechToText() async {
    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }

    if (_speechToText.isListening) {
      await _speechToText.cancel();
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
          _isListening = false;
        });
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 5),
    );
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _textController.clear();
    widget.onSendMessage(message);
    widget.onToggleStreaming(true);

    setState(() {
      _isSending = false;
    });

    // Simulate AI response
    await Future.delayed(Duration(seconds: 2));
    widget.onToggleStreaming(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Input Field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: widget.focusNode,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                fillColor: theme.cardColor.withOpacity(0.5),
                filled: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.2, // Better line height
              ),
              onChanged: (text) {
                // Force rebuild to update button icon
                setState(() {});
              },
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isSending,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Dynamic Button (Mic or Send)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: _textController.text.trim().isEmpty
                  ? null
                  : LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(26),
              color: _textController.text.trim().isEmpty
                  ? theme.iconTheme.color?.withOpacity(0.1)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: _textController.text.trim().isEmpty
                    ? (_speechToText.isAvailable ? _startSpeechToText : null)
                    : (_isSending ? null : _sendMessage),
                child: Center(
                  child: Icon(
                    _textController.text.trim().isEmpty
                        ? (_isListening ? Icons.stop : Icons.mic)
                        : (_isSending ? Icons.autorenew : Icons.send),
                    size: 22,
                    color: _textController.text.trim().isEmpty
                        ? theme.iconTheme.color
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}