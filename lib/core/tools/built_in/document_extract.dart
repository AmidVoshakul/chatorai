import 'dart:io';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/tools/document_extractor_service.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:path/path.dart' as p;

class DocumentExtractTool {
  final DocumentExtractorService _service;

  DocumentExtractTool({DocumentExtractorService? service})
    : _service = service ?? DocumentExtractorService();

  ToolDef get definition {
    return ToolDef(
      id: 'document_extract',
      description:
          'Extract text and images from uploaded documents (PDF, DOCX, TXT, MD). '
          'Use this tool when the user uploads a document file and asks you to read or analyze it.\n'
          'Returns markdown with embedded images (for PDF pages and DOCX media).',
      inputSchema: {
        'type': 'object',
        'properties': {
          'file_path': {
            'type': 'string',
            'description': 'Absolute path to the document file',
          },
          'page_limit': {
            'type': 'integer',
            'description':
                'Max pages to render for PDF (default: all, max 10)',
            'minimum': 1,
            'maximum': 10,
          },
          'pdf_page_timeout': {
            'type': 'integer',
            'description':
                'Timeout in seconds for each PDF page render (default: 15, min 5)',
            'minimum': 5,
            'default': 15,
          },
        },
        'required': ['file_path'],
      },
      execute: (input, ctx) async {
        final filePath = input['file_path'] as String?;
        if (filePath == null || filePath.trim().isEmpty) {
          throw ToolExecutionError(
            'document_extract',
            'file_path is required and cannot be empty',
          );
        }

        String safePath;
        try {
          safePath = resolveSafePath(
            filePath,
            allowedRoots: managedReadRoots,
          );
        } on ArgumentError {
          throw ToolExecutionError(
            'document_extract',
            'path is outside allowed roots',
          );
        }

        final boundary = FilesystemBoundary(workspace: Directory.current);
        final resolution = boundary.resolve(safePath);
        try {
          if (resolution.isExternal &&
              !isWithinAnyRoot(resolution.path, managedReadRoots)) {
            await ctx.ask(
              permission: 'external_directory',
              patterns: [resolution.path],
              always: [resolution.path],
              metadata: {
                'filepath': resolution.path,
                'parentDir': p.dirname(resolution.path),
                'tool': 'document_extract',
              },
            );
          }
          if (!isWithinAnyRoot(resolution.path, managedReadRoots)) {
            await ctx.ask(permission: 'read', patterns: [resolution.path]);
          }
        } on PermissionDeniedError {
          throw ToolExecutionError(
            'document_extract',
            'permission denied: $safePath',
          );
        }

        final file = File(safePath);
        if (!file.existsSync()) {
          throw ToolExecutionError(
            'document_extract',
            'file not found: $safePath',
          );
        }

        final type = _service.detectType(safePath);
        if (type == DocumentType.unknown) {
          throw ToolExecutionError(
            'document_extract',
            'unsupported file type. Supported: PDF, DOCX, TXT, MD.',
          );
        }

        LogTags.skills.logInfo(
          'document_extract: extracting ${type.name} from "${p.basename(safePath)}"',
        );

        final pageLimit = input['page_limit'] as int?;
        final pdfPageTimeout = input['pdf_page_timeout'] != null
            ? Duration(seconds: input['pdf_page_timeout'] as int)
            : null;
        final abortSignal = ctx.abortSignal;

        try {
          final result = await _service.extract(
            safePath,
            pageLimit: pageLimit,
            pdfPageTimeout: pdfPageTimeout,
            onAbort: () {
              if (abortSignal?.isCancelled ?? false) {
                throw StateError('Document extraction cancelled');
              }
            },
          );
          return ToolOutput(
            result,
            metadata: {
              'file_path': safePath,
              'type': type.name,
              'content_length': result.length,
            },
          );
        } catch (e, s) {
          LogTags.skills.logError(
            'document_extract: failed for "${p.basename(safePath)}"',
            e,
            s,
          );
          throw ToolExecutionError(
            'document_extract',
            e.toString(),
          );
        }
      },
    );
  }
}

ToolDef createDocumentExtractTool() => DocumentExtractTool().definition;
