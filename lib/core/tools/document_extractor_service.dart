import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf_render_maintained/pdf_render.dart';
import 'package:xml/xml.dart';

import 'truncation_service.dart';

enum DocumentType { pdf, docx, txt, md, unknown }

class DocumentExtractorService {
  static const _maxPageImages = 10;
  static const _renderScale = 2.0;
  static const _maxTextFileBytes = 5 * 1024 * 1024;
  static const _maxDocxBytes = 20 * 1024 * 1024;
  static const _maxPdfBytes = 100 * 1024 * 1024;
  static const _defaultPdfOpenTimeout = Duration(seconds: 15);
  static const _defaultPdfPageTimeout = Duration(seconds: 30);

  DocumentType detectType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'pdf':
      case 'docx':
      case 'txt':
      case 'md':
      case 'markdown':
        final type = _detectByExtension(ext);
        if (type == DocumentType.unknown) return type;
        final headerType = _detectByMagicBytes(filePath);
        return headerType == DocumentType.unknown ? type : headerType;
      default:
        return _detectByMagicBytes(filePath);
    }
  }

  DocumentType _detectByExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return DocumentType.pdf;
      case 'docx':
        return DocumentType.docx;
      case 'txt':
        return DocumentType.txt;
      case 'md':
      case 'markdown':
        return DocumentType.md;
      default:
        return DocumentType.unknown;
    }
  }

  DocumentType _detectByMagicBytes(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return DocumentType.unknown;
      final raf = file.openSync(mode: FileMode.read);
      try {
        final header = raf.readSync(8);
        if (header.length >= 4) {
          if (header[0] == 0x25 && header[1] == 0x50 &&
              header[2] == 0x44 && header[3] == 0x46) {
            return DocumentType.pdf;
          }
        }
        if (header.length >= 2) {
          if (header[0] == 0x50 && header[1] == 0x4B) {
            return DocumentType.docx;
          }
        }
        return DocumentType.unknown;
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return DocumentType.unknown;
    }
  }

  Future<String> extract(
    String filePath, {
    int? pageLimit,
    Duration? pdfPageTimeout,
    void Function()? onAbort,
  }) async {
    final type = detectType(filePath);
    if (type == DocumentType.unknown) {
      throw ArgumentError('Unsupported file type: $filePath');
    }

    switch (type) {
      case DocumentType.pdf:
        return _extractPdf(
          filePath,
          pageLimit: pageLimit,
          pdfPageTimeout: pdfPageTimeout,
          onAbort: onAbort,
        );
      case DocumentType.docx:
        return _extractDocx(filePath);
      case DocumentType.txt:
        return _extractTextFile(filePath);
      case DocumentType.md:
        return _extractTextFile(filePath);
      case DocumentType.unknown:
        throw StateError('unreachable');
    }
  }

  Future<String> _extractPdf(
    String filePath, {
    int? pageLimit,
    Duration? pdfPageTimeout,
    void Function()? onAbort,
  }) async {
    onAbort?.call();

    final stat = await File(filePath).stat();
    if (stat.size > _maxPdfBytes) {
      throw ArgumentError(
        'PDF too large: ${stat.size} bytes (max $_maxPdfBytes)',
      );
    }

    final pageTimeout = pdfPageTimeout ?? _defaultPdfPageTimeout;
    final openTimeout =
        pageTimeout > _defaultPdfOpenTimeout
            ? pageTimeout
            : _defaultPdfOpenTimeout;

    final doc = await PdfDocument
        .openFile(filePath)
        .timeout(openTimeout, onTimeout: () {
      throw TimeoutException('PDF open timed out');
    });
    try {
      final totalPages = doc.pageCount;
      final limit = pageLimit ?? totalPages;
      final pages = limit.clamp(1, totalPages).clamp(1, _maxPageImages);

      final buffer = StringBuffer();
      buffer.writeln('# PDF Document: ${p.basename(filePath)}');
      buffer.writeln('- Total pages: $totalPages');
      buffer.writeln(
        '- Pages shown: $pages${pages < totalPages ? ' (limited)' : ''}',
      );
      buffer.writeln('');

      for (int i = 1; i <= pages; i++) {
        onAbort?.call();

        final page = await doc.getPage(i);
        try {
          final fullWidth = (page.width * _renderScale).round();
          final fullHeight = (page.height * _renderScale).round();
          final image = await page
              .render(width: fullWidth, height: fullHeight)
              .timeout(pageTimeout, onTimeout: () {
            throw TimeoutException('Page $i render timed out');
          });
          try {
            final pngBytes = _rgbaToPng(
              image.pixels,
              image.width,
              image.height,
            );
            final b64 = base64Encode(pngBytes);
            buffer.writeln('### Page $i');
            buffer.writeln('![](${'data:image/png;base64,$b64'})');
            buffer.writeln('');
          } finally {
            image.dispose();
          }
        } finally {
        }
      }

      return buffer.toString();
    } finally {
      await doc.dispose();
    }
  }

  Future<String> _extractDocx(String filePath) async {
    final stat = await File(filePath).stat();
    if (stat.size > _maxDocxBytes) {
      throw ArgumentError(
        'DOCX too large: ${stat.size} bytes (max $_maxDocxBytes)',
      );
    }

    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final buffer = StringBuffer();
    buffer.writeln('# DOCX Document: ${p.basename(filePath)}');
    buffer.writeln('');

    final documentFile = archive.findFile('word/document.xml');
    if (documentFile != null) {
      final xmlContent = utf8.decode(documentFile.content);
      final document = XmlDocument.parse(xmlContent);
      final paragraphs = document.findAllElements('w:p');
      for (final p in paragraphs) {
        final texts = p
            .descendants
            .whereType<XmlText>()
            .map((t) => t.value.trim())
            .where((t) => t.isNotEmpty)
            .join(' ');
        if (texts.isNotEmpty) {
          buffer.writeln(texts);
          buffer.writeln('');
        }
      }
    }

    final mediaFiles = archive.files
        .where((f) => f.name.startsWith('word/media/'))
        .toList();

    if (mediaFiles.isNotEmpty) {
      buffer.writeln('---');
      buffer.writeln('### Embedded Media');
      buffer.writeln('');

      for (int i = 0; i < mediaFiles.length; i++) {
        final media = mediaFiles[i];
        final ext = p.extension(media.name).toLowerCase().replaceFirst('.', '');
        if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].contains(ext)) {
          final b64 = base64Encode(media.content);
          final mime = ext == 'jpg' ? 'jpeg' : ext;
          buffer.writeln(
            '![Media ${i + 1}](${'data:image/$mime;base64,$b64'})',
          );
          buffer.writeln('');
        }
      }
    }

    return buffer.toString();
  }

  Future<String> _extractTextFile(String filePath) async {
    final stat = await File(filePath).stat();
    if (stat.size > _maxTextFileBytes) {
      final fullContent = await File(filePath).readAsString();
      final fullBytes = utf8.encode(fullContent);
      final truncatedBytes = fullBytes.sublist(0, _maxTextFileBytes);
      final truncated = utf8.decode(truncatedBytes, allowMalformed: true);
      final fullPath = await TruncationService.instance.write(fullContent);
      return '# ${p.basename(filePath)} (truncated)\n\n'
          'File size: ${stat.size} bytes (limit: $_maxTextFileBytes).\n'
          'Showing first $_maxTextFileBytes bytes.\n'
          'Full file written to: $fullPath\n'
          'Use the Read tool with filePath: "$fullPath" to read the full content.\n\n'
          '```\n$truncated\n```\n';
    }
    final content = await File(filePath).readAsString();
    return '# ${p.basename(filePath)}\n\n```\n$content\n```\n';
  }

  Uint8List _rgbaToPng(Uint8List rgba, int width, int height) {
    final expected = width * height * 4;
    if (rgba.length < expected) {
      throw StateError(
        'Insufficient pixel data: expected $expected bytes, got ${rgba.length}',
      );
    }
    final safeBytes = Uint8List.sublistView(rgba, 0, expected);
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: safeBytes.buffer,
      numChannels: 4,
    );
    return Uint8List.fromList(img.encodePng(image));
  }
}
