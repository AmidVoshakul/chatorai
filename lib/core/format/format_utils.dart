import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Checks whether [cmd] is available on PATH.
Future<String?> which(String cmd) async {
  try {
    final result = await Process.run('which', [cmd]);
    return result.exitCode == 0 ? cmd : null;
  } catch (_) {
    return null;
  }
}

/// Searches up the directory tree from [startDir] for a file named [filename].
Future<List<String>> findFilesUp(String filename, String startDir) async {
  final results = <String>[];
  var current = p.normalize(p.absolute(startDir));

  while (true) {
    final candidate = p.join(current, filename);
    if (File(candidate).existsSync()) {
      results.add(candidate);
    }

    final parent = p.dirname(current);
    if (parent == current) break;
    current = parent;
  }

  return results;
}

/// Reads a text file as a string.
Future<String> readText(String path) async {
  return File(path).readAsString();
}

/// Reads and decodes a JSON file.
Future<Map<String, dynamic>> readJson(String path) async {
  final text = await readText(path);
  return json.decode(text) as Map<String, dynamic>;
}

/// Resolves a Node package binary via npx, if available.
Future<String?> npmWhich(String packageName) async {
  try {
    final npx = await which('npx');
    if (npx == null) return null;
    final result = await Process.run(npx, [
      packageName,
      '--version',
    ]).timeout(const Duration(seconds: 10));
    return result.exitCode == 0 ? packageName : null;
  } catch (_) {
    return null;
  }
}

/// Runs a process and returns stdout as string, with nothrow-friendly contract.
Future<ProcessTextResult> processText(
  List<String> command, {
  Map<String, String>? environment,
  Duration timeout = const Duration(seconds: 30),
}) async {
  try {
    final result = await Process.run(
      command.first,
      command.skip(1).toList(),
      environment: environment,
    ).timeout(timeout);
    return ProcessTextResult(
      text: result.stdout.toString(),
      code: result.exitCode,
    );
  } on TimeoutException {
    return ProcessTextResult(text: '', code: -1);
  } catch (_) {
    return ProcessTextResult(text: '', code: -1);
  }
}

class ProcessTextResult {
  final String text;
  final int code;
  const ProcessTextResult({required this.text, required this.code});
}

/// Runs a process with a timeout and returns stdout/stderr/exitCode.
Future<ProcessResult> runWithTimeout(
  List<String> command, {
  Map<String, String>? environment,
  String? workingDirectory,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final result = await Process.run(
    command.first,
    command.skip(1).toList(),
    environment: environment,
    workingDirectory: workingDirectory,
  ).timeout(timeout);
  return result;
}
