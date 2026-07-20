#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:yaml/yaml.dart';

/// Reads version from pubspec.yaml and updates lib/core/cli/app_version.dart.
/// This ensures the CLI --version output stays in sync with the package version.
void main() async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('ERROR: pubspec.yaml not found');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final yaml = loadYaml(content);
  final version = yaml['version'] as String?;

  if (version == null || version.isEmpty) {
    stderr.writeln('ERROR: Could not find version in pubspec.yaml');
    exit(1);
  }

  final versionFile = File('lib/core/cli/app_version.dart');
  final newContent =
      '''/// Auto-generated from pubspec.yaml.
/// Do not edit manually — run `dart run tool/update_version.dart` instead.
const String appVersion = '$version';
''';

  versionFile.writeAsStringSync(newContent);
  print('✓ Updated app_version.dart to $version');
}
