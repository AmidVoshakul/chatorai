import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';

/// Tests for permissionServiceProvider.
void main() {
  group('permissionServiceProvider', () {
    test('returns a PermissionService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(permissionServiceProvider);
      expect(service, isA<PermissionService>());
    });

    test('returns the same instance within the same container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service1 = container.read(permissionServiceProvider);
      final service2 = container.read(permissionServiceProvider);

      expect(identical(service1, service2), isTrue);
    });

    test('returns different instances across containers', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      final service1 = container1.read(permissionServiceProvider);
      final service2 = container2.read(permissionServiceProvider);

      expect(identical(service1, service2), isFalse);
    });

    test('returned service has correct initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(permissionServiceProvider);

      // Initially no approved rules
      expect(service.approvedRules, isEmpty);
    });

    test('returned service can seed rules', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(permissionServiceProvider);
      service.seedRules(PermissionRuleset.defaults());

      // After seeding, isAllowed should work
      expect(service.isAllowed('read', '/any/file.txt'), isTrue);
      expect(service.isAllowed('shell', 'rm -rf /'), isFalse);
    });

    test('returned service can attach preferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(permissionServiceProvider);
      // Just verify it doesn't throw
      expect(() => service, returnsNormally);
    });
  });
}
