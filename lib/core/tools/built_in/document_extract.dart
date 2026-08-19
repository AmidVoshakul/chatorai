import 'dart:io';

import 'package:chatorai/core/tools/document_extractor_service.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

// ---------------------------------------------------------------------------
// document_extract_pdf
// ---------------------------------------------------------------------------

ToolDef createDocumentExtractPdfTool() {
  return ToolDef(
    id: 'document_extract_pdf',
    description:
        'Extract text and rendered page images from a PDF file. '
        'Returns text per page followed by a base64 PNG render of each page '
        'so multimodal models can fully understand the document.\n\n'
        'Use this tool ONLY for PDF files. For text-based documents (.txt, .md, source code) '
        'use the Read tool instead. For DOCX files use document_extract_docx. '
        'For XLSX spreadsheets use document_extract_xlsx.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description':
              'Absolute path to a PDF file. Glob patterns are expanded to the first match. '
              'Comma-separated paths are split and the first path is used.',
        },
        'pages': {
          'type': 'array',
          'description':
              'Page range for PDF: [start, end] (1-based, end exclusive). '
              'Omit to process all pages.',
          'items': {'type': 'integer', 'minimum': 1},
          'minItems': 2,
          'maxItems': 2,
        },
        'render_scale': {
          'type': 'number',
          'description':
              'PNG render scale for PDF pages (1.0 = 72dpi, 2.0 = 144dpi). '
              'Higher = sharper images, more tokens. Default: 1.5',
          'minimum': 0.5,
          'maximum': 4.0,
          'default': 1.5,
        },
      },
      'required': ['file_path'],
    },
    execute: (input, ctx) async {
      await DocumentExtractorService.initPdfRx();

      final rawPath = input['file_path'] as String?;
      if (rawPath == null || rawPath.trim().isEmpty) {
        return ToolOutput(
          'Error: file_path is required and cannot be empty',
          metadata: {'error': true},
        );
      }

      final renderScale =
          (input['render_scale'] as num?)?.toDouble() ??
          DocumentExtractorService.defaultRenderScale;

      final pagesRaw = input['pages'] as List?;
      PageRange? pages;
      if (pagesRaw != null && pagesRaw.length == 2) {
        final start = pagesRaw[0] as int?;
        final end = pagesRaw[1] as int?;
        if (start != null && start >= 1 && end != null && end >= start) {
          pages = PageRange(start, end);
        }
      }

      final resolved = _resolvePath(rawPath.trim());
      if (resolved == null) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      final projectRoot = workspaceRuntimeCurrent.path;
      final safePath = await _autoAllowPath(resolved, projectRoot, ctx);
      if (safePath == null) {
        return ToolOutput(
          'Error: path resolution failed',
          metadata: {'error': true},
        );
      }

      final file = File(safePath);
      if (!file.existsSync()) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      try {
        final content = await DocumentExtractorService().extractPdf(
          safePath,
          pages: pages,
          maxFileSizeBytes:
              DocumentExtractorService.maxFileSizeMb * 1024 * 1024,
          renderScale: renderScale,
        );
        return ToolOutput(
          '# ${p.basename(safePath)}\n$content',
          metadata: {
            'type': 'pdf',
            'file_paths': [safePath],
          },
        );
      } catch (e) {
        return ToolOutput('Error: $e', metadata: {'error': true});
      }
    },
  );
}

// ---------------------------------------------------------------------------
// document_extract_docx
// ---------------------------------------------------------------------------

ToolDef createDocumentExtractDocxTool() {
  return ToolDef(
    id: 'document_extract_docx',
    description:
        'Extract text and embedded media from a DOCX (Word) file. '
        'Returns paragraphs as plain text and base64-encoded images from the document.\n\n'
        'Use this tool ONLY for DOCX files. For text-based documents (.txt, .md, source code) '
        'use the Read tool instead. For PDF files use document_extract_pdf. '
        'For XLSX spreadsheets use document_extract_xlsx.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description':
              'Absolute path to a DOCX file. Glob patterns are expanded to the first match. '
              'Comma-separated paths are split and the first path is used.',
        },
      },
      'required': ['file_path'],
    },
    execute: (input, ctx) async {
      final rawPath = input['file_path'] as String?;
      if (rawPath == null || rawPath.trim().isEmpty) {
        return ToolOutput(
          'Error: file_path is required and cannot be empty',
          metadata: {'error': true},
        );
      }

      final resolved = _resolvePath(rawPath.trim());
      if (resolved == null) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      final projectRoot = workspaceRuntimeCurrent.path;
      final safePath = await _autoAllowPath(resolved, projectRoot, ctx);
      if (safePath == null) {
        return ToolOutput(
          'Error: path resolution failed',
          metadata: {'error': true},
        );
      }

      final file = File(safePath);
      if (!file.existsSync()) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      try {
        final content = await DocumentExtractorService().extractDocx(safePath);
        return ToolOutput(
          '# ${p.basename(safePath)}\n$content',
          metadata: {
            'type': 'docx',
            'file_paths': [safePath],
          },
        );
      } catch (e) {
        return ToolOutput('Error: $e', metadata: {'error': true});
      }
    },
  );
}

// ---------------------------------------------------------------------------
// document_extract_xlsx
// ---------------------------------------------------------------------------

ToolDef createDocumentExtractXlsxTool() {
  return ToolDef(
    id: 'document_extract_xlsx',
    description:
        'Extract data from an XLSX (Excel) spreadsheet file. '
        'Returns cell values as a markdown-style table grouped by sheet.\n\n'
        'Use this tool ONLY for XLSX files. For text-based documents (.txt, .md, source code) '
        'use the Read tool instead. For PDF files use document_extract_pdf. '
        'For DOCX files use document_extract_docx.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description':
              'Absolute path to an XLSX file. Glob patterns are expanded to the first match. '
              'Comma-separated paths are split and the first path is used.',
        },
        'sheet': {
          'type': 'string',
          'description':
              'Name of the sheet to extract. Omit to use the first available sheet.',
        },
      },
      'required': ['file_path'],
    },
    execute: (input, ctx) async {
      final rawPath = input['file_path'] as String?;
      if (rawPath == null || rawPath.trim().isEmpty) {
        return ToolOutput(
          'Error: file_path is required and cannot be empty',
          metadata: {'error': true},
        );
      }

      final sheet = input['sheet'] as String?;

      final resolved = _resolvePath(rawPath.trim());
      if (resolved == null) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      final projectRoot = workspaceRuntimeCurrent.path;
      final safePath = await _autoAllowPath(resolved, projectRoot, ctx);
      if (safePath == null) {
        return ToolOutput(
          'Error: path resolution failed',
          metadata: {'error': true},
        );
      }

      final file = File(safePath);
      if (!file.existsSync()) {
        return ToolOutput(
          'Error: file not found: "$rawPath"',
          metadata: {'error': true},
        );
      }

      try {
        final content = await DocumentExtractorService().extractXlsx(
          safePath,
          sheet: sheet,
        );
        return ToolOutput(
          content,
          metadata: {
            'type': 'xlsx',
            'file_paths': [safePath],
          },
        );
      } catch (e) {
        return ToolOutput('Error: $e', metadata: {'error': true});
      }
    },
  );
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String? _resolvePath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.contains('*') || trimmed.contains('?')) {
    final glob = Glob(trimmed);
    final matches = glob
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }
  if (trimmed.contains(',')) {
    final parts = trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.first;
  }
  final f = File(trimmed);
  return f.existsSync() ? trimmed : null;
}

Future<String?> _autoAllowPath(
  String raw,
  String projectRoot,
  ToolContext ctx,
) async {
  String safePath;
  try {
    safePath = resolveSafePath(raw, allowedRoots: managedReadRoots);
  } on ArgumentError {
    safePath = p.normalize(p.isAbsolute(raw) ? raw : p.join(projectRoot, raw));
  }

  final boundary = FilesystemBoundary(workspace: workspaceRuntimeCurrent);
  final resolution = boundary.resolve(safePath);
  if (resolution.isExternal &&
      !isWithinAnyRoot(resolution.path, managedReadRoots)) {
    try {
      await ctx.ask(
        permission: 'external_directory',
        patterns: [resolution.path],
        always: [resolution.path],
        metadata: {
          'toolName': 'document_extract',
          'requestedPath': resolution.path,
        },
      );
    } on PermissionDeniedError catch (e) {
      LogTags.skills.logWarning(
        'document_extract: permission denied for ${resolution.path}: $e',
      );
      return null;
    } on PermissionRejectedError catch (e) {
      LogTags.skills.logWarning(
        'document_extract: permission rejected for ${resolution.path}: $e',
      );
      return null;
    }
  }
  return resolution.path;
}
