import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';

class CodeBlock extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlock({
    super.key,
    required this.code,
    required this.language,
  });

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _isCollapsed = false;

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
          // Header with language, collapse button, and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(8),
                bottom: _isCollapsed ? const Radius.circular(8) : Radius.zero,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Language and collapse button
                Row(
                  children: [
                    // Collapse/expand button
                    IconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.chevron_right : Icons.expand_more,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                      tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.language.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Copy button
                IconButton(
                  icon: Icon(
                    Icons.copy_all,
                    color: isDark ? Colors.white70 : Colors.black87,
                    size: 18,
                  ),
                  onPressed: () {
                    MessageUtils.copyMessage(
                      content: widget.code,
                      context: context,
                    );
                  },
                  tooltip: 'Copy code',
                  splashRadius: 16,
                  hoverColor: isDark ? Colors.white10 : Colors.black12,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          // Code content with syntax highlighting (only if not collapsed)
          if (!_isCollapsed)
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
                            widget.code,
                            language: widget.language.toLowerCase(),
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