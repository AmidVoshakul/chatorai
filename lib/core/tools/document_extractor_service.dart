import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_document/pdf_document.dart' as pdf_doc;
import 'package:pdf_graphics/pdf_graphics.dart' as pdfg;
import 'package:pdfrx/pdfrx.dart' as rxd;
import 'package:pdfrx_engine/pdfrx_engine.dart' as rxengine;
import 'package:xml/xml.dart';

enum DocumentType { pdf, docx, xlsx, unknown }

class PageRange {
  final int start;
  final int? end;

  const PageRange(this.start, this.end);

  (int, int) toStartEnd(int totalPages) {
    final s = start < 1 ? 1 : start;
    final e = end == null
        ? totalPages
        : (end! > totalPages ? totalPages : end!);
    return (s, e.clamp(s, totalPages));
  }
}

class DocumentExtractorService {
  static const _maxDocxBytes = 20 * 1024 * 1024;
  static const _maxXlsxBytes = 20 * 1024 * 1024;
  static const maxFileSizeMb = 50;
  static const defaultRenderScale = 1.5;

  static bool _pdfrxAvailable = true;
  static bool get pdfrxAvailable => _pdfrxAvailable;

  static Future<void> initPdfRx() async {
    try {
      await rxd.pdfrxInitialize();
    } on Exception catch (_) {
      _pdfrxAvailable = false;
    } catch (_) {
      _pdfrxAvailable = false;
    }
  }

  DocumentType detectType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'pdf':
      case 'docx':
      case 'xlsx':
      case 'xls':
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
      case 'xlsx':
      case 'xls':
        return DocumentType.xlsx;
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
        if (header.length >= 4 &&
            header[0] == 0x25 &&
            header[1] == 0x50 &&
            header[2] == 0x44 &&
            header[3] == 0x46) {
          return DocumentType.pdf;
        }
        if (header.length >= 2 && header[0] == 0x50 && header[1] == 0x4B) {
          return DocumentType.docx;
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
    PageRange? pages,
    int? maxFileSizeMb,
    double renderScale = defaultRenderScale,
    void Function()? onAbort,
    String? sheet,
  }) async {
    final type = detectType(filePath);
    if (type == DocumentType.unknown) {
      throw ArgumentError('unsupported file type: $filePath');
    }

    final sizeLimit =
        (maxFileSizeMb ?? DocumentExtractorService.maxFileSizeMb) * 1024 * 1024;

    switch (type) {
      case DocumentType.pdf:
        return extractPdf(
          filePath,
          pages: pages,
          maxFileSizeBytes: sizeLimit,
          renderScale: renderScale,
          onAbort: onAbort,
        );
      case DocumentType.docx:
        final docxSize = await File(filePath).stat().then((s) => s.size);
        if (docxSize > _maxDocxBytes) {
          throw ArgumentError(
            'DOCX too large: $docxSize bytes (max $_maxDocxBytes)',
          );
        }
        return extractDocx(filePath);
      case DocumentType.xlsx:
        final xlsxSize = await File(filePath).stat().then((s) => s.size);
        if (xlsxSize > _maxXlsxBytes) {
          throw ArgumentError(
            'XLSX too large: $xlsxSize bytes (max $_maxXlsxBytes)',
          );
        }
        return extractXlsx(filePath, sheet: sheet);
      case DocumentType.unknown:
        throw StateError('unreachable');
    }
  }

  Future<String> extractPdf(
    String filePath, {
    PageRange? pages,
    required int maxFileSizeBytes,
    double renderScale = defaultRenderScale,
    void Function()? onAbort,
  }) async {
    onAbort?.call();

    final stat = await File(filePath).stat();
    if (stat.size > maxFileSizeBytes) {
      throw ArgumentError(
        'PDF too large: ${stat.size} bytes (max $maxFileSizeBytes)',
      );
    }

    final bytes = await File(filePath).readAsBytes();
    final doc = pdf_doc.PdfDocument.open(bytes);
    final totalPages = doc.pageCount;
    final effectivePages = pages ?? const PageRange(1, null);
    final (start, end) = effectivePages.toStartEnd(totalPages);

    final buffer = StringBuffer();
    buffer.writeln('# PDF Document: ${p.basename(filePath)}');
    buffer.writeln('- Total pages: $totalPages');
    if (pages != null) {
      buffer.writeln('- Pages shown: $start–${end - 1} (limited)');
    }
    buffer.writeln('');

    for (var i = start - 1; i < end; i++) {
      onAbort?.call();

      final pageText = pdfg.PdfTextExtractor.extract(doc, i);
      final text = pageText.text.trim();
      if (text.isNotEmpty) {
        buffer.writeln('### Page ${i + 1}');
        buffer.writeln(text);
        buffer.writeln('');
      }

      if (_pdfrxAvailable) {
        rxengine.PdfImage? renderedPage;
        rxengine.PdfDocument? pageDoc;
        try {
          final result = await _openPdfRxPage(bytes, i);
          pageDoc = result.$1;
          final rxPage = result.$2;
          if (rxPage != null) {
            final scale = renderScale.clamp(0.5, 4.0);
            final w = (rxPage.width * scale).toInt();
            final h = (rxPage.height * scale).toInt();

            renderedPage = await rxPage.render(
              width: w,
              height: h,
              backgroundColor: 0xFFFFFFFF,
            );

            if (renderedPage != null) {
              final img = _bgraToImage(
                renderedPage.pixels,
                renderedPage.width,
                renderedPage.height,
              );
              final pngBytes = Uint8List.fromList(encodePng(img));
              final b64 = base64Encode(pngBytes);
              buffer.write(
                '![Page ${i + 1}]'
                '(data:image/png;base64,$b64)',
              );
              buffer.writeln('');
            }
          }
        } on Exception catch (_) {
          // PDFium unavailable — silently skip rendering for this page
        } finally {
          renderedPage?.dispose();
          pageDoc?.dispose();
        }
      }
    }

    return buffer.toString();
  }

  Image _bgraToImage(Uint8List bgra, int width, int height) {
    final img = Image(
      width: width,
      height: height,
      format: Format.uint8,
      numChannels: 4,
    );
    final len = width * height;
    final src = bgra;
    for (var i = 0; i < len; i++) {
      final si = i << 2;
      final r = src[si + 2];
      final g = src[si + 1];
      final b = src[si];
      final a = src[si + 3];
      img.data!.setPixelRgba(i % width, i ~/ width, r, g, b, a);
    }
    return img;
  }

  Future<(rxengine.PdfDocument?, rxengine.PdfPage?)> _openPdfRxPage(
    Uint8List bytes,
    int pageIndex,
  ) async {
    if (!_pdfrxAvailable) return (null, null);
    try {
      final doc = await rxengine.PdfDocument.openData(bytes);
      final page = doc.pages[pageIndex];
      await page.ensureLoaded();
      return (doc, page);
    } on Exception {
      return (null, null);
    }
  }

  Future<String> extractDocx(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final buffer = StringBuffer();

    final documentFile = archive.findFile('word/document.xml');
    if (documentFile != null) {
      final xmlContent = utf8.decode(documentFile.content);
      final document = XmlDocument.parse(xmlContent);
      final paragraphs = document.findAllElements('w:p');
      for (final para in paragraphs) {
        final texts = para.descendants
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

  Future<String> extractXlsx(String filePath, {String? sheet}) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final sheetNames = <String>[];
    final worksheetFiles = <String>[];
    final sharedStrings = <String>[];

    for (final file in archive.files) {
      final lower = file.name.toLowerCase();
      if (lower == 'xl/workbook.xml') {
        final xml = utf8.decode(file.content);
        final doc = XmlDocument.parse(xml);
        final sheetElems = doc.findAllElements('sheet').toList();
        for (final s in sheetElems) {
          final name = s.getAttribute('name');
          sheetNames.add(name ?? '');
        }
        for (var i = 0; i < sheetElems.length; i++) {
          worksheetFiles.add('xl/worksheets/sheet${i + 1}.xml');
        }
      } else if (lower == 'xl/sharedstrings.xml') {
        final xml = utf8.decode(file.content);
        final doc = XmlDocument.parse(xml);
        for (final si in doc.findAllElements('si')) {
          final parts = si.findAllElements('t').map((t) => t.value).toList();
          sharedStrings.add(parts.join(' '));
        }
      }
    }

    final targetIndex = sheet != null
        ? sheetNames.indexWhere((n) => n.toLowerCase() == sheet.toLowerCase())
        : 0;

    if (targetIndex < 0) {
      final available = sheetNames.isEmpty
          ? 'unknown'
          : sheetNames.map((n) => '"$n"').join(', ');
      return '# ${p.basename(filePath)}\n\nSheet "$sheet" not found. Available: $available';
    }

    final targetFile = targetIndex < worksheetFiles.length
        ? worksheetFiles[targetIndex]
        : null;
    if (targetFile == null) {
      return '# ${p.basename(filePath)}\n\nNo sheets found.';
    }

    final displayName = sheetNames.isNotEmpty
        ? sheetNames[targetIndex]
        : 'Sheet${targetIndex + 1}';

    final sheetFile = archive.files.firstWhere(
      (f) => f.name.toLowerCase() == targetFile.toLowerCase(),
      orElse: () => throw ArchiveException(
        'Sheet file not found for "$displayName" (expected: $targetFile). '
        'Available: ${archive.files.map((f) => f.name).join(", ")}',
      ),
    );
    final sheetXml = utf8.decode(sheetFile.content);
    final sheetDoc = XmlDocument.parse(sheetXml);
    final rows = sheetDoc.findAllElements('row');

    final buffer = StringBuffer();
    buffer.writeln('# ${p.basename(filePath)} — Sheet: $displayName');
    buffer.writeln('');

    for (final row in rows) {
      final cells = row.findAllElements('c').toList();
      final values = <String>[];
      for (final cell in cells) {
        final type = cell.getAttribute('t');
        final text = cell.descendants.whereType<XmlText>().join();

        if (text.isEmpty) {
          values.add('');
          continue;
        }

        if (type == 's') {
          final index = int.tryParse(text) ?? -1;
          values.add(
            index >= 0 && index < sharedStrings.length
                ? sharedStrings[index]
                : text,
          );
        } else {
          values.add(text);
        }
      }
      if (values.isEmpty) continue;
      buffer.writeln('${values.map((v) => '| $v ').join()}|');
    }

    return buffer.toString();
  }
}
