import 'dart:io';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _agentTemplate = '''
---
name: %ID%
description: temporary test agent
mode: subagent
---
Test prompt body.
''';

void main() {
  // The registry is a process-wide singleton, so all scenarios run inside a
  // single test to keep ordering deterministic.
  test('reload picks up added and deleted project agent files', () async {
    final previousCwd = Directory.current;
    final tmp = await Directory.systemTemp.createTemp('agent_reload_test');
    final agentsDir = Directory(p.join(tmp.path, '.chatorai', 'agents'));
    await agentsDir.create(recursive: true);

    final firstFile = File(p.join(agentsDir.path, 'zz_reload_first.md'));
    await firstFile.writeAsString(
      _agentTemplate.replaceAll('%ID%', 'zz_reload_first'),
    );

    try {
      Directory.current = tmp.path;
      final registry = AgentRegistry();
      await registry.init();

      expect(registry.get('zz_reload_first'), isNotNull);

      // Adding a file becomes visible after reload().
      final secondFile = File(p.join(agentsDir.path, 'zz_reload_second.md'));
      await secondFile.writeAsString(
        _agentTemplate.replaceAll('%ID%', 'zz_reload_second'),
      );
      await registry.reload();
      expect(registry.get('zz_reload_second'), isNotNull);

      // Deleting a file removes the definition after reload(), while
      // built-ins survive the rebuild.
      await firstFile.delete();
      await registry.reload();
      expect(registry.get('zz_reload_first'), isNull);
      expect(registry.get('build'), isNotNull);
    } finally {
      Directory.current = previousCwd;
      if (await tmp.exists()) await tmp.delete(recursive: true);
    }
  });
}
