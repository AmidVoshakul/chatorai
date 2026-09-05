import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/permission/permission_storage.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/evaluator.dart';

void main() {
  group('SharedPrefsPermissionStorage', () {
    late SharedPreferences prefs;
    late SharedPrefsPermissionStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = SharedPrefsPermissionStorage(prefs);
    });

    test('saveAlways and loadAlways roundtrip', () async {
      final rules = {
        'read:/tmp/ws1/*': 'allow',
        'edit:/tmp/ws1/*.dart': 'allow',
      };

      await storage.saveAlways('/tmp/ws1', rules);
      final loaded = await storage.loadAlways('/tmp/ws1');

      expect(loaded, equals(rules));
    });

    test('loadAlways returns empty map for missing workspace', () async {
      final loaded = await storage.loadAlways('/tmp/nonexistent');
      expect(loaded, isEmpty);
    });

    test('clearAlways removes stored rules', () async {
      final rules = {'read:/tmp/ws1/*': 'allow'};
      await storage.saveAlways('/tmp/ws1', rules);
      await storage.clearAlways('/tmp/ws1');

      final loaded = await storage.loadAlways('/tmp/ws1');
      expect(loaded, isEmpty);
    });

    test('different workspaces have isolated storage', () async {
      final rules1 = {'read:/tmp/ws1/*': 'allow'};
      final rules2 = {'edit:/tmp/ws2/*': 'allow'};

      await storage.saveAlways('/tmp/ws1', rules1);
      await storage.saveAlways('/tmp/ws2', rules2);

      final loaded1 = await storage.loadAlways('/tmp/ws1');
      final loaded2 = await storage.loadAlways('/tmp/ws2');

      expect(loaded1, equals(rules1));
      expect(loaded2, equals(rules2));
    });

    test('overwrite replaces previous rules for same workspace', () async {
      final rules1 = {'read:/tmp/ws1/*': 'allow'};
      final rules2 = {'edit:/tmp/ws1/*': 'deny'};

      await storage.saveAlways('/tmp/ws1', rules1);
      await storage.saveAlways('/tmp/ws1', rules2);

      final loaded = await storage.loadAlways('/tmp/ws1');
      expect(loaded, equals(rules2));
    });

    test('loadAlways migrates old hashCode key to new stable key', () async {
      final workspacePath = '/tmp/ws_migration';
      final rules = {
        'read:/tmp/ws_migration/*': 'allow',
        'edit:/tmp/ws_migration/*.dart': 'deny',
      };

      final oldKey = 'permission_always_${workspacePath.hashCode}';
      final newKey =
          'permission_always_${base64Url.encode(utf8.encode(workspacePath))}';

      // Seed SharedPreferences with the OLD key only.
      SharedPreferences.setMockInitialValues({oldKey: json.encode(rules)});
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPrefsPermissionStorage(prefs);

      final loaded = await storage.loadAlways(workspacePath);
      expect(loaded, equals(rules));

      // The new stable key must now exist with the same JSON payload.
      expect(prefs.getString(newKey), json.encode(rules));
      // The old hashCode key must have been removed.
      expect(prefs.containsKey(oldKey), isFalse);
    });
  });
}
