import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chatorai/shared/utils/link_launcher.dart';

class _FakeLauncher extends Mock {
  Future<bool> call(Uri uri, {LaunchMode mode});
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(LaunchMode.platformDefault);
  });

  group('isHttpHttpsUrl', () {
    test('http and https are accepted', () {
      expect(isHttpHttpsUrl('http://example.com'), isTrue);
      expect(isHttpHttpsUrl('https://example.com'), isTrue);
    });

    test('non-http schemes are rejected', () {
      expect(isHttpHttpsUrl('javascript:alert(1)'), isFalse);
      expect(isHttpHttpsUrl('data:text/html,<h1>hi</h1>'), isFalse);
      expect(isHttpHttpsUrl('file:///etc/passwd'), isFalse);
      expect(isHttpHttpsUrl('tel:+1234567890'), isFalse);
      expect(isHttpHttpsUrl('mailto:user@example.com'), isFalse);
    });

    test('empty and invalid strings are rejected', () {
      expect(isHttpHttpsUrl(''), isFalse);
      expect(isHttpHttpsUrl(null), isFalse);
      expect(isHttpHttpsUrl('not a url'), isFalse);
    });
  });

  group('launchExternalLink', () {
    test('invalidScheme does not call launcher', () async {
      final launcher = _FakeLauncher();
      final result = await launchExternalLink(
        'javascript:alert(1)',
        launcher: launcher.call,
      );
      expect(result, LinkLaunchResult.invalidScheme);
      verifyNever(() => launcher(any(), mode: any(named: 'mode')));
    });

    test('successful launch returns opened', () async {
      final launcher = _FakeLauncher();
      when(
        () => launcher(any(), mode: any(named: 'mode')),
      ).thenAnswer((_) async => true);

      final result = await launchExternalLink(
        'https://example.com',
        launcher: launcher.call,
      );
      expect(result, LinkLaunchResult.opened);
      verify(
        () => launcher(
          Uri.parse('https://example.com'),
          mode: LaunchMode.externalApplication,
        ),
      ).called(1);
    });

    test('failed launch returns failed', () async {
      final launcher = _FakeLauncher();
      when(
        () => launcher(any(), mode: any(named: 'mode')),
      ).thenAnswer((_) async => false);

      final result = await launchExternalLink(
        'https://example.com',
        launcher: launcher.call,
      );
      expect(result, LinkLaunchResult.failed);
    });

    test('exception during launch returns failed', () async {
      final launcher = _FakeLauncher();
      when(
        () => launcher(any(), mode: any(named: 'mode')),
      ).thenThrow(Exception('platform error'));

      final result = await launchExternalLink(
        'https://example.com',
        launcher: launcher.call,
      );
      expect(result, LinkLaunchResult.failed);
    });
  });
}
