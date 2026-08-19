import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/utils/android_storage_permission.dart';

void main() {
  group('Android storage permission helpers', () {
    test('isAllFilesAccessGranted is true on non-Android platforms', () async {
      expect(await isAllFilesAccessGranted(), isTrue);
    });

    test('ensureAllFilesAccess succeeds without Android', () async {
      expect(await ensureAllFilesAccess(), isTrue);
    });

    test('allFilesAccessHint mentions All files access', () {
      final hint = allFilesAccessHint();
      expect(hint, contains('All files access'));
      expect(hint, contains('Settings'));
    });
  });
}
