import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool) onToggleStreaming;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onToggleStreaming,
    this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isSending = false;
  bool _plusActive = false;
  Timer? _plusTimer;

  // Ключ для получения позиции кнопки "+"
  final GlobalKey _plusKey = GlobalKey();

  @override
  void dispose() {
    _textController.dispose();
    _plusTimer?.cancel();
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
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
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

    await Future.delayed(const Duration(seconds: 2));
    widget.onToggleStreaming(false);
  }

  // Открыть всплывающее меню над кнопкой "+"
  Future<void> _showPlusMenu() async {
    // Включаем визуальную подсветку кнопки
    setState(() {
      _plusActive = true;
    });

    // Получаем позицию кнопки
    final RenderBox? box = _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      // Если не удалось получить позицию — просто временно подсветим и выйдем
      _plusTimer?.cancel();
      _plusTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _plusActive = false);
      });
      return;
    }

    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    // Позиция меню: над кнопкой. Подбираем верхнюю границу (top) немного выше offset.dy
    final double menuHeightEstimate = 56.0; // примерная высота пункта меню
    final double top = offset.dy - (menuHeightEstimate + 8.0); // 8px отступ
    final double left = offset.dx;
    final double right = offset.dx + size.width;
    final double bottom = offset.dy + size.height;

    // Показать меню и дождаться выбора
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      items: [
        PopupMenuItem<String>(
          value: 'add_image',
          child: Row(
            children: const [
              Icon(Icons.image, size: 20),
              SizedBox(width: 8),
              Text('+ add image to file'),
            ],
          ),
        ),
      ],
      elevation: 4,
    );

    // Обработка выбора
    if (selected == 'add_image') {
      _onAddImage();
    }

    // Снимаем подсветку кнопки после закрытия меню
    if (mounted) {
      setState(() {
        _plusActive = false;
      });
    }
  }

  // Действие при выборе "add image to file"
  void _onAddImage() {
    // TODO: реализовать добавление изображения в файл
    // Здесь можно открыть диалог выбора изображения, камеру и т.д.
  }

  int _computeMaxLines(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final maxHeight = deviceHeight * 0.4;
    final lines = (maxHeight / 24).floor();
    return lines < 1 ? 1 : lines;
  }

  bool _isMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _isMobileLayout(context);
    final maxLines = _computeMaxLines(context);

    final backgroundColor = theme.cardColor;

    // Размер круглой кнопки (уменьшенный)
    const double buttonSize = 44.0;
    const double iconSize = 20.0;
    const double sidePadding = 20.0;
    const double bottomPadding = 12.0;

    Widget buildActionButton({
      Key? key,
      required Widget child,
      Gradient? gradient,
      Color? bgColor,
      VoidCallback? onTap,
    }) {
      return Container(
        key: key,
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? bgColor : null,
          borderRadius: BorderRadius.circular(buttonSize / 2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonSize / 2),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      );
    }

    return Container(
      padding: isMobile ? const EdgeInsets.only(top: 16) : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMobile ? backgroundColor : Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: isMobile
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            : BorderRadius.circular(0),
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 48,
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: backgroundColor,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.2,
                    ),
                    onChanged: (text) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, bottomPadding),
                  child: Row(
                    children: [
                      // Левая кнопка "+" — фон НЕ зависит от текста, только от _plusActive.
                      // Ключ нужен для позиционирования меню.
                      buildActionButton(
                        key: _plusKey,
                        gradient: _plusActive
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        bgColor: _plusActive ? null : theme.iconTheme.color?.withOpacity(0.1),
                        onTap: () async {
                          // Показываем меню над кнопкой
                          await _showPlusMenu();
                        },
                        child: Icon(
                          Icons.add,
                          size: iconSize,
                          color: _plusActive ? Colors.white : theme.iconTheme.color,
                        ),
                      ),

                      const Spacer(),

                      // Правая динамическая кнопка (микрофон / отправка)
                      buildActionButton(
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
                        bgColor: _textController.text.trim().isEmpty
                            ? theme.iconTheme.color?.withOpacity(0.1)
                            : null,
                        onTap: _textController.text.trim().isEmpty
                            ? (_speechToText.isAvailable ? _startSpeechToText : null)
                            : (_isSending ? null : _sendMessage),
                        child: Icon(
                          _textController.text.trim().isEmpty
                              ? (_isListening ? Icons.stop : Icons.mic)
                              : (_isSending ? Icons.autorenew : Icons.send),
                          size: iconSize,
                          color: _textController.text.trim().isEmpty ? theme.iconTheme.color : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
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
                      height: 1.2,
                    ),
                    onChanged: (text) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
                const SizedBox(width: 12),
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
