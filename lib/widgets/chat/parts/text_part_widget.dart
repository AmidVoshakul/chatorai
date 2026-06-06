import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/models/chat_message.dart';

class TextPartWidget extends StatelessWidget {
  final TextPart part;

  const TextPartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    if (part.content.isEmpty) {
      return const SizedBox(height: 16);
    }

    return MarkdownBody(
      data: part.content,
      styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
      selectable: true,
    );
  }
}
