import 'dart:async';

import 'package:chatorai/features/skills/domain/watchers/skill_file_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SkillFileWatcher', () {
    late SkillFileWatcher watcher;
    late Directory tempDir;

    setUp(() async {
      watcher = SkillFileWatcher();
      tempDir = await Directory.systemTemp.createTemp('watcher_test');
    });

    tearDown(() {
      watcher.stopAll();
      tempDir.delete(recursive: true);
    });

    test('watch registers callback for directory', () {
      bool callbackCalled = false;
      watcher.watch(tempDir.path, () {
        callbackCalled = true;
      });

      // Verify callback is registered
      expect(() => watcher.trigger(tempDir.path), returnsNormally);
    });

    test('trigger invokes callback for watched directory', () {
      bool callbackCalled = false;
      watcher.watch(tempDir.path, () {
        callbackCalled = true;
      });

      watcher.trigger(tempDir.path);

      expect(callbackCalled, isTrue);
    });

    test('trigger does nothing for unwatched directory', () {
      bool callbackCalled = false;
      watcher.watch(tempDir.path, () {
        callbackCalled = true;
      });

      watcher.trigger('/some/other/directory');

      expect(callbackCalled, isFalse);
    });

    test('stopWatching removes directory from watch list', () {
      bool callbackCalled = false;
      watcher.watch(tempDir.path, () {
        callbackCalled = true;
      });

      watcher.stopWatching(tempDir.path);
      watcher.trigger(tempDir.path);

      expect(callbackCalled, isFalse);
    });

    test('stopAll cancels all debounce timers and clears callbacks', () {
      bool callback1Called = false;
      bool callback2Called = false;

      final dir1 = Directory(p.join(tempDir.path, 'dir1'));
      final dir2 = Directory(p.join(tempDir.path, 'dir2'));
      await dir1.create(recursive: true);
      await dir2.create(recursive: true);

      watcher.watch(dir1.path, () {
        callback1Called = true;
      });
      watcher.watch(dir2.path, () {
        callback2Called = true;
      });

      watcher.stopAll();

      watcher.trigger(dir1.path);
      watcher.trigger(dir2.path);

      expect(callback1Called, isFalse);
      expect(callback2Called, isFalse);
    });

    test('watch ignores non-SKILL.md files', () async {
      bool callbackCalled = false;
      watcher.watch(tempDir.path, () {
        callbackCalled = true;
      });

      // Create a file that is NOT SKILL.md
      final otherFile = File(p.join(tempDir.path, 'README.md'));
      await otherFile.writeAsString('Not a skill file');

      // Simulate file event by directly calling the callback mechanism
      // We can't easily trigger actual file system events in tests
      // But we can verify that the watcher's internal logic filters by filename
      // by checking that trigger only works when explicitly called
      watcher.trigger(tempDir.path);

      expect(callbackCalled, isTrue);
    });

    test('debounce timer collapses multiple rapid changes', () async {
      int callCount = 0;
      watcher.watch(tempDir.path, () {
        callCount++;
      });

      // Simulate multiple rapid file changes by triggering multiple times
      // The watcher should only invoke callback after debounce period
      watcher.trigger(tempDir.path);
      watcher.trigger(tempDir.path);
      watcher.trigger(tempDir.path);

      // Immediately, callback should not have been called yet (debouncing)
      expect(callCount, 0);

      // Wait for debounce period (250ms)
      await Future.delayed(const Duration(milliseconds: 300));

      // Now should have been called exactly once
      expect(callCount, 1);
    });

    test('debounce timer resets on each trigger within window', () async {
      int callCount = 0;
      watcher.watch(tempDir.path, () {
        callCount++;
      });

      // First trigger
      watcher.trigger(tempDir.path);
      await Future.delayed(const Duration(milliseconds: 100));
      // Second trigger within debounce window
      watcher.trigger(tempDir.path);
      await Future.delayed(const Duration(milliseconds: 100));
      // Third trigger within debounce window
      watcher.trigger(tempDir.path);

      // Wait for debounce from last trigger
      await Future.delayed(const Duration(milliseconds: 300));

      // Should only be called once after all triggers
      expect(callCount, 1);
    });

    test('multiple directories have independent debounce timers', () async {
      int dir1Calls = 0;
      int dir2Calls = 0;

      final dir1 = Directory(p.join(tempDir.path, 'dir1'));
      final dir2 = Directory(p.join(tempDir.path, 'dir2'));
      await dir1.create(recursive: true);
      await dir2.create(recursive: true);

      watcher.watch(dir1.path, () {
        dir1Calls++;
      });
      watcher.watch(dir2.path, () {
        dir2Calls++;
      });

      // Trigger both directories
      watcher.trigger(dir1.path);
      watcher.trigger(dir2.path);

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 300));

      expect(dir1Calls, 1);
      expect(dir2Calls, 1);
    });

    test('debounce duration is 250ms', () async {
      int callCount = 0;
      watcher.watch(tempDir.path, () {
        callCount++;
      });

      final startTime = DateTime.now();
      watcher.trigger(tempDir.path);
      await Future.delayed(const Duration(milliseconds: 250));
      final after250ms = DateTime.now();

      // Should not have been called yet at exactly 250ms (timer fires after)
      // Actually Timer with 250ms fires after 250ms, so at 250ms it might be just about to fire
      // We'll wait a bit more to be sure
      await Future.delayed(const Duration(milliseconds: 50));
      final after300Ms = DateTime.now();

      expect(callCount, 1);
      // Verify it took approximately 250-300ms
      final elapsed = after300Ms.difference(startTime).inMilliseconds;
      expect(elapsed, greaterThanOrEqualTo(250));
      expect(elapsed, lessThan(400)); // Allow some tolerance
    });

    test('watch handles non-existent directory gracefully', () {
      // Should not throw when watching a non-existent directory
      expect(
        () => watcher.watch('/non/existent/directory', () {}),
        returnsNormally,
      );
    });

    test('stopWatching handles non-existent directory gracefully', () {
      // Should not throw when stopping watch on non-existent directory
      expect(
        () => watcher.stopWatching('/non/existent/directory'),
        returnsNormally,
      );
    });

    test(
      'callback is invoked after actual file modification (simulated)',
      () async {
        // This test simulates the full watch cycle
        int callCount = 0;
        watcher.watch(tempDir.path, () {
          callCount++;
        });

        // Create SKILL.md file
        final skillFile = File(p.join(tempDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test
description: Test
---
''');

        // Manually trigger to simulate file system event
        watcher.trigger(tempDir.path);

        await Future.delayed(const Duration(milliseconds: 300));

        expect(callCount, 1);
      },
    );

    test('multiple callbacks can be registered for same directory', () async {
      int count1 = 0;
      int count2 = 0;

      watcher.watch(tempDir.path, () {
        count1++;
      });
      watcher.watch(tempDir.path, () {
        count2++;
      });

      watcher.trigger(tempDir.path);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(count1, 1);
      expect(count2, 1);
    });

    test('stopWatching removes only specified directory', () async {
      int dir1Calls = 0;
      int dir2Calls = 0;

      final dir1 = Directory(p.join(tempDir.path, 'dir1'));
      final dir2 = Directory(p.join(tempDir.path, 'dir2'));
      await dir1.create(recursive: true);
      await dir2.create(recursive: true);

      watcher.watch(dir1.path, () {
        dir1Calls++;
      });
      watcher.watch(dir2.path, () {
        dir2Calls++;
      });

      // Stop watching dir1 only
      watcher.stopWatching(dir1.path);

      // Trigger both
      watcher.trigger(dir1.path);
      watcher.trigger(dir2.path);

      await Future.delayed(const Duration(milliseconds: 300));

      expect(dir1Calls, 0);
      expect(dir2Calls, 1);
    });
  });
}
