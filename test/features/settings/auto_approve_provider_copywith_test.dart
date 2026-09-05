import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/gui/features/settings/providers/auto_approve_provider.dart';

void main() {
  group('AutoApproveCategory.copyWith', () {
    test(
      'copyWith with clearDefaultAction=true sets defaultAction to null',
      () {
        const category = AutoApproveCategory(
          id: 'read',
          label: 'Read',
          description: 'Read files',
          defaultAction: 'allow',
          exceptions: {},
          isFileCategory: true,
        );

        final updated = category.copyWith(clearDefaultAction: true);

        expect(updated.defaultAction, isNull);
        expect(updated.id, 'read');
        expect(updated.label, 'Read');
      },
    );

    test('copyWith with defaultAction overrides existing', () {
      const category = AutoApproveCategory(
        id: 'read',
        label: 'Read',
        description: 'Read files',
        defaultAction: 'allow',
        exceptions: {},
        isFileCategory: true,
      );

      final updated = category.copyWith(defaultAction: 'deny');

      expect(updated.defaultAction, 'deny');
    });

    test('copyWith without arguments preserves all values', () {
      const category = AutoApproveCategory(
        id: 'read',
        label: 'Read',
        description: 'Read files',
        defaultAction: 'allow',
        exceptions: {'/tmp/*': 'deny'},
        isFileCategory: true,
      );

      final updated = category.copyWith();

      expect(updated.defaultAction, 'allow');
      expect(updated.exceptions, {'/tmp/*': 'deny'});
      expect(updated.isFileCategory, true);
    });

    test('copyWith with exceptions merges correctly', () {
      const category = AutoApproveCategory(
        id: 'read',
        label: 'Read',
        description: 'Read files',
        defaultAction: 'allow',
        exceptions: {'/tmp/*': 'deny'},
        isFileCategory: true,
      );

      final updated = category.copyWith(exceptions: {'/home/*': 'ask'});

      expect(updated.exceptions, {'/home/*': 'ask'});
    });
  });
}
