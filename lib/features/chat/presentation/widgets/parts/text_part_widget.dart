import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/markdown_with_headings.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/code_block.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/table_block.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TextPartWidget extends StatefulWidget {
  final TextPart part;

  const TextPartWidget({super.key, required this.part});

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

  /// Rendered children for everything rendered so far (the "prefix").
  /// Kept as a flat list: on each streaming append we add ONE tail widget
  /// to this same list, so the widget tree never nests and no content is lost.
  List<Widget>? _prefixChildren;

  /// Cache of finalized block widgets (keyed by stable signature).
  /// Only non-trailing blocks are cached, so the entry set stays bounded.
  final Map<String, Widget> _blockCache = {};

  @override
  void didUpdateWidget(covariant TextPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newContent = widget.part.content;
    final oldContent = oldWidget.part.content;
    if (newContent == oldContent) return;
    // Only a pure append keeps the incremental prefix cache valid. If the
    // content shrank, changed mid-string (edit/regeneration), or is a fresh
    // part for a different message, the cache must be rebuilt from scratch.
    final isAppend = oldContent.isNotEmpty &&
        newContent.length > oldContent.length &&
        newContent.startsWith(oldContent);
    if (!isAppend) {
      _resetCache();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeKey = Theme.of(context).brightness.toString();
    if (_lastThemeKey != themeKey) {
      _lastThemeKey = themeKey;
      _resetCache();
    }
  }

  void _resetCache() {
    _lastContent = null;
    _prefixChildren = null;
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

    // Identical content → reuse the rendered prefix verbatim (cheap).
    if (_lastContent == part.content && _prefixChildren != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _prefixChildren!,
      );
    }

    final prev = _lastContent;
    _lastContent = part.content;

    // Fast streaming path: content grew only by appending plain text that
    // cannot start a new markdown construct. Reuse the already-rendered
    // prefix (flat list) and append just the new tail as plain text.
    if (prev != null &&
        part.content.length > prev.length &&
        part.content.startsWith(prev) &&
        _prefixChildren != null) {
      final tail = part.content.substring(prev.length);
      if (_isPlainTextTail(tail)) {
        _prefixChildren!.add(
          RepaintBoundary(child: SelectableText(tail)),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _prefixChildren!,
        );
      }
    }

    // Full (re)build — happens on block-boundary changes or completion.
    // Non-trailing blocks are pulled from the cache, so only the still-growing
    // trailing block is actually re-parsed.
    final widgets = _buildCustomMarkdownContent(context);
    _prefixChildren = List<Widget>.from(widgets);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _prefixChildren!,
    );
  }

  /// True only when [tail] is plain text that cannot open a markdown block
  /// or inline construct at its start. Conservative on purpose: if unsure,
  /// we fall back to a full markdown re-parse (still cheap via block cache).
  bool _isPlainTextTail(String tail) {
    if (tail.isEmpty) return false;
    // A newline could begin a new block (heading/list/quote/table), so the
    // tail must be a single, unbroken line of plain prose.
    if (tail.contains('\n')) return false;
    // Scan the whole tail: any of these characters can open or appear inside a
    // markdown construct mid-stream (code fence, heading, table pipe), so we
    // must fall back to a full re-parse rather than risk mis-rendering it as
    // plain text.
    for (final char in tail.characters) {
      if (char == '`' || char == '#' || char == '|') return false;
    }
    final first = tail.characters.first;
    const markdownStarters = {
      '*',
      '_',
      '-',
      '+',
      '>',
      '[',
      '!',
    };
    if (markdownStarters.contains(first)) return false;
    // Ordered list "1. "
    if (tail.length >= 2 &&
        tail.characters.first == '1' &&
        tail.characters.elementAt(1) == '.') {
      return false;
    }
    return true;
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
              _Block(_BlockKind.code, currentCodeBlock, language: currentLanguage),
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

    if (currentText.isNotEmpty) blocks.add(_Block(_BlockKind.text, currentText));
    if (currentCodeBlock.isNotEmpty) {
      blocks.add(
        _Block(_BlockKind.code, currentCodeBlock.trim(), language: currentLanguage),
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
        widgets.add(_buildBlockWidget(block, styleSheet));
      } else {
        final key = block.kind == _BlockKind.table
            ? '${block.kind.index}|${block.tableLines?.join('\u0000') ?? ''}'
            : '${block.kind.index}|${block.language ?? ''}|${block.text}';
        final cached = _blockCache[key];
        if (cached != null) {
          widgets.add(cached);
        } else {
          final w = _buildBlockWidget(block, styleSheet);
          _blockCache[key] = w;
          widgets.add(w);
        }
      }
    }

    return widgets;
  }

  Widget _buildBlockWidget(_Block block, MarkdownStyleSheet styleSheet) {
    switch (block.kind) {
      case _BlockKind.text:
        return _buildMarkdownBlock(block.text, styleSheet);
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

  Widget _buildMarkdownBlock(String data, MarkdownStyleSheet styleSheet) {
    return RepaintBoundary(
      child: MarkdownBody(
        data: data,
        styleSheet: styleSheet,
        selectable: true,
        builders: HeadingBuilder.headingBuilders(),
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
