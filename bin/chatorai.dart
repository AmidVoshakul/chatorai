// ignore_for_file: avoid_print
import 'dart:io';

import 'package:chatorai/core/cli/cli_commands.dart';

/// Dev entry point for `dart run bin/chatorai.dart`.
///
/// The production CLI logic lives in `lib/core/cli/cli_commands.dart` and is
/// also embedded in the compiled GUI binary, so `chatorai <command>` works
/// after installation without a separate executable.
Future<void> main(List<String> args) async {
  await runCliIfRequested(args);
  exit(0);
}
