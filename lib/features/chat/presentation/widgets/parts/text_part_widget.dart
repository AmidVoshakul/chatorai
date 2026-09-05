import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/markdown_with_headings.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/code_block.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/table_block.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TextPartWidget extends StatefulWidget {
  final TextPart part;
  final String messageId;
  final List<MarkdownHeadingInfoWithKey> headings;

  const TextPartWidget({
    super.key,
    required this.part,
    required this.messageId,
    this.headings = const [],
  });

  @override
  State<TextPartWidget> createState() => _TextPartWidgetState();
}

enum _BlockKind { text, code, table }

class _Block {
  final _BlockKind kind;
  final String text;
  final String? language;
  final List<String>? tableLines;

  _Block(this.kind, this.text, {this.language, this.tableLines});
}

class _TextPartWidgetState extends State<TextPartWidget> {
  String? _lastContent;
  String? _lastThemeKey;

  /// Memoized widget tree for the last rendered content, so unrelated
  /// rebuilds (scroll, parent state changes) don't re-parse markdown.
  Widget? _cachedColumn;

  /// Cache of finalized block widgets (keyed by stable signature).
  /// Only non-trailing blocks are cached, so the entry set stays bounded.
  final Map<String, Widget> _blockCache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Markdown styling is derived from the theme; invalidate the memoized
    // content when the brightness changes so it re-parses with fresh styles.
    final themeKey = Theme.of(context).brightness.toString();
    if (_lastThemeKey != themeKey) {
      _lastThemeKey = themeKey;
      _resetCache();
    }
  }

  void _resetCache() {
    _lastContent = null;
    _cachedColumn = null;
    _blockCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;

    if (part.content.isEmpty && part.isStreaming) {
      return const _StreamingCursor();
    }

    if (part.content.isEmpty) {
      return const SizedBox(height: 16);
    }

    // Identical content → reuse the rendered tree verbatim (cheap).
    if (_lastContent == part.content && _cachedColumn != null) {
      return _cachedColumn!;
    }
    _lastContent = part.content;

    // Full (re)build — happens on every content change (streaming append,
    // block-boundary transitions, or completion). Non-trailing blocks are
    // pulled from the cache, so only the still-growing trailing block is
    // actually re-parsed.
    final widgets = _buildCustomMarkdownContent(context);
    _cachedColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
    return _cachedColumn!;
  }

  List<_Block> _parseBlocks(List<String> lines) {
    final blocks = <_Block>[];
    String currentText = '';
    bool inCode = false;
    String currentLanguage = 'text';
    String currentCodeBlock = '';
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      if (line.startsWith('```')) {
        if (inCode) {
          if (currentText.isNotEmpty) {
            blocks.add(_Block(_BlockKind.text, currentText));
            currentText = '';
          }
          if (currentCodeBlock.isNotEmpty) {
            blocks.add(
              _Block(
                _BlockKind.code,
                currentCodeBlock,
                language: currentLanguage,
              ),
            );
            currentCodeBlock = '';
          }
          inCode = false;
        } else {
          if (currentText.isNotEmpty) {
            blocks.add(_Block(_BlockKind.text, currentText));
            currentText = '';
          }
          inCode = true;
          currentLanguage = line.substring(3).trim();
          if (currentLanguage.isEmpty) currentLanguage = 'text';
        }
      } else if (inCode) {
        currentCodeBlock += '$line\n';
      } else {
        final tableResult = TableParser.extractTableAt(lines, i);
        if (tableResult != null) {
          if (currentText.isNotEmpty) {
            blocks.add(_Block(_BlockKind.text, currentText));
            currentText = '';
          }
          blocks.add(
            _Block(_BlockKind.table, '', tableLines: tableResult.lines),
          );
          i = tableResult.endIndex;
          continue;
        } else {
          currentText += '$line\n';
        }
      }
      i++;
    }

    if (currentText.isNotEmpty) {
      blocks.add(_Block(_BlockKind.text, currentText));
    }
    if (currentCodeBlock.isNotEmpty) {
      blocks.add(
        _Block(
          _BlockKind.code,
          currentCodeBlock.trim(),
          language: currentLanguage,
        ),
      );
    }

    return blocks;
  }

  List<Widget> _buildCustomMarkdownContent(BuildContext context) {
    final lines = widget.part.content.split('\n');
    final styleSheet = ChatoraiMarkdownStyles.getMarkdownStyles(context);

    final blocks = _parseBlocks(lines);
    final widgets = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      // The trailing block is still streaming — always rebuild it.
      // Every earlier (finalized) block is cached by signature.
      final isTrailing = i == blocks.length - 1;
      if (isTrailing) {
        widgets.add(_buildBlockWidget(context, block, styleSheet));
      } else {
        final key = block.kind == _BlockKind.table
            ? '${block.kind.index}|${block.tableLines?.join('\u0000') ?? ''}'
            : '${block.kind.index}|${block.language ?? ''}|${block.text}';
        final cached = _blockCache[key];
        if (cached != null) {
          widgets.add(cached);
        } else {
          final w = _buildBlockWidget(context, block, styleSheet);
          _blockCache[key] = w;
          widgets.add(w);
        }
      }
    }

    return widgets;
  }

  Widget _buildBlockWidget(
    BuildContext context,
    _Block block,
    MarkdownStyleSheet styleSheet,
  ) {
    switch (block.kind) {
      case _BlockKind.text:
        return _buildMarkdownBlock(context, block.text, styleSheet);
      case _BlockKind.code:
        return CodeBlock(code: block.text, language: block.language ?? 'text');
      case _BlockKind.table:
        final rows = TableParser.parseTableLines(block.tableLines!);
        if (rows != null && rows.isNotEmpty) {
          return TableBlock(rows: rows);
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildMarkdownBlock(
    BuildContext context,
    String data,
    MarkdownStyleSheet styleSheet,
  ) {
    return RepaintBoundary(
      child: MarkdownWithHeadings(
        data: data,
        headings: widget.headings,
        messageId: widget.messageId,
      ),
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 16,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
