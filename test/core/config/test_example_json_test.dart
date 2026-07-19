import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatorai.example.json', () {
    test('parses without error and matches schema shape', () {
      final file = File('chatorai.example.json');
      expect(file.existsSync(), isTrue, reason: 'example file must exist');

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final config = ChatOrAIConfig.fromJson(json);
      expect(config, isNotNull);

      // provider section (if present) must contain valid structure
      if (config.provider != null) {
        for (final entry in config.provider!.providers.values) {
          expect(entry.options?.baseURL, isA<String?>());
          for (final model in entry.models.values) {
            expect(model.limit?.context, isA<int?>());
            expect(model.limit?.output, isA<int?>());
          }
        }
      }
    });
  });
}
