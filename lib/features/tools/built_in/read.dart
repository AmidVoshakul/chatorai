import 'dart:convert';
import 'dart:io';

import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:path/path.dart' as p;

import 'package:chatorai/shared/utils/path_sandbox.dart';

const _binaryExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.ico',
  '.webp',
  '.pdf',
  '.zip',
  '.tar',
  '.gz',
  '.bz2',
  '.7z',
  '.rar',
  '.exe',
  '.dll',
  '.so',
  '.dylib',
  '.bin',
  '.class',
  '.jar',
  '.wasm',
  '.pyc',
  '.o',
  '.a',
  '.lib',
  '.obj',
  '.mp3',
  '.mp4',
  '.avi',
  '.mov',
  '.mkv',
  '.flac',
  '.ogg',
  '.sqlite',
  '.db',
  '.sqlite3',
  '.ttf',
  '.otf',
  '.woff',
  '.woff2',
  '.eot',
};

bool _isLikelyBinary(String filePath, List<int> bytes) {
  final ext = p.extension(filePath).toLowerCase();
  if (_binaryExtensions.contains(ext)) return true;

  var nonPrintable = 0;
  final sample = bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes;
  for (final b in sample) {
    if (b == 0 || (b < 32 && b != 9 && b != 10 && b != 13)) {
      nonPrintable++;
      if (nonPrintable > sample.length * 0.3) return true;
    }
  }
  return false;
}

ToolDef createReadTool() {
  return ToolDef(
    id: 'read',
    description: 'Read a file',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description': 'Path to the file to read',
        },
        'offset': {
          'type': 'integer',
          'description': 'Line offset to start from',
        },
        'limit': {'type': 'integer', 'description': 'Maximum lines to read'},
      },
      'required': ['file_path'],
    },
    execute: (input, ctx) async {
      final filePath =
          input['file_path'] as String? ?? input['path'] as String?;
      if (filePath == null) {
        return ToolOutput(
          'Error: file_path is required',
          metadata: {'error': true},
        );
      }

      final safePath = resolveSafePath(filePath);
      await ctx.ask(permission: 'read', patterns: [safePath]);
      final offset = input['offset'] as int? ?? 0;
      final limit = input['limit'] as int? ?? 2000;
      final file = File(safePath);
      if (!await file.exists()) {
        return ToolOutput(
          'Error: file not found: $safePath',
          metadata: {'error': true},
        );
      }

      final bytes = await file.readAsBytes();

      if (_isLikelyBinary(safePath, bytes)) {
        final size = bytes.length;
        final sizeStr = size > 1024 * 1024
            ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(size / 1024).toStringAsFixed(1)} KB';
        return ToolOutput(
          '[Binary file: $safePath ($sizeStr)]\n'
          'Binary files cannot be displayed as text. Use appropriate tools.',
          metadata: {'error': true, 'binary': true, 'size': size},
        );
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final lines = text.split('\n');
      final start = offset.clamp(0, lines.length);
      final end = (offset + limit).clamp(start, lines.length);
      final selected = lines.sublist(start, end).join('\n');

      return ToolOutput(
        selected,
        metadata: {
          'lines': lines.length,
          'offset': start,
          'limit': end - start,
          'binary': false,
          'file_path': safePath,
        },
      );
    },
  );
}
