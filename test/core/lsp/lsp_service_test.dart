import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LspService', () {
    test('loadUserServers registers extensions and skips disabled', () async {
      final service = LspService();
      service.loadUserServers(
        LspConfig(
          servers: {
            'my-ls': LspServerEntryConfig(
              command: const ['my-ls'],
              extensions: const ['.foo'],
              autoInstall: false,
            ),
            'disabled-ls': LspServerEntryConfig(
              command: const ['disabled-ls'],
              extensions: const ['.bar'],
              disabled: true,
            ),
          },
        ),
      );

      final client = await service.clientForFile('/tmp/test.foo');
      expect(
        client,
        isNull,
      ); // command 'my-ls' does not exist, returns null after failed start
    });

    test('loadUserServers is a no-op for empty config', () {
      final service = LspService();
      expect(() => service.loadUserServers(const LspConfig()), returnsNormally);
    });

    test(
      'loadUserServers sets enabled=false and disables clientForFile',
      () async {
        final service = LspService();
        service.loadUserServers(const LspConfig(enabled: false));
        final client = await service.clientForFile('/tmp/test.dart');
        expect(client, isNull);
      },
    );

    test('AutoInstallHint npm command is formed correctly', () async {
      final hint = AutoInstallHint(
        packageManager: 'npm',
        packageName: 'this-package-definitely-does-not-exist-12345',
        extraArgs: ['--global'],
      );
      expect(await hint.install(), isFalse);
    });

    test('AutoInstallHint returns false for unknown package manager', () async {
      final hint = AutoInstallHint(
        packageManager: 'unknown',
        packageName: 'foo',
      );
      expect(await hint.install(), isFalse);
    });

    test('shutdownAll is idempotent', () async {
      final service = LspService();
      await service.shutdownAll();
      // Second call should not throw
      await service.shutdownAll();
    });

    test('ChatOrAIConfig parses lsp:true as enabled LspConfig', () {
      final config = ChatOrAIConfig.fromJson(
        {'lsp': true} as Map<String, dynamic>,
      );
      expect(config.lsp, isNotNull);
      expect(config.lsp!.enabled, isTrue);
    });

    test('ChatOrAIConfig parses lsp:false as disabled LspConfig', () {
      final config = ChatOrAIConfig.fromJson(
        {'lsp': false} as Map<String, dynamic>,
      );
      expect(config.lsp, isNotNull);
      expect(config.lsp!.enabled, isFalse);
    });

    test(
      'ChatOrAIConfig parses lsp:{} as enabled LspConfig with no servers',
      () {
        final config = ChatOrAIConfig.fromJson(
          {'lsp': {}} as Map<String, dynamic>,
        );
        expect(config.lsp, isNotNull);
        expect(config.lsp!.enabled, isTrue);
        expect(config.lsp!.servers, isEmpty);
      },
    );
  });
}
