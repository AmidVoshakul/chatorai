import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final String language;

  const CodeBlock({
    Key? key,
    required this.code,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE9ECEF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_all, color: isDark ? Colors.white70 : Colors.black87, size: 18),
                  onPressed: () {
                    // Используем улучшенную логику копирования из MessageUtils
                    MessageUtils.copyMessage(
                      content: code,
                      context: context,
                    );
                  },
                  tooltip: 'Copy code',
                  splashRadius: 20,
                  hoverColor: isDark ? Colors.white10 : Colors.black12,
                ),
              ],
            ),
          ),
// Code content with syntax highlighting using appropriate theme
          Container(
            color: isDark 
              ? const Color(0xFF23241F) 
              : const Color(0xFFF6F8FA),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: HighlightView(
                          code,
                          language: language.toLowerCase(),
                          theme: isDark ? monokaiSublimeTheme : githubTheme,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.5, // Line spacing
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}