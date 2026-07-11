import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/agents/agent_registry.dart';

// Note: AgentRegistry tests require initialization.
// These tests are designed to run after the registry is initialized by the app.
// For standalone testing, use test/core/agents/test_agent_parser.dart and test_agent_loader.dart

void main() {
  // ── TokenCounter ───────────────────────────────────────────────────────

  group('TokenCounter', () {
    test('estimate returns 0 for empty string', () {
      expect(TokenCounter.estimate(''), 0);
    });

    test('estimate returns length ~/ 4 for ASCII text', () {
      expect(TokenCounter.estimate('abcd'), 1);
      expect(TokenCounter.estimate('abcdefgh'), 2);
      expect(TokenCounter.estimate('a'), 0);
      expect(TokenCounter.estimate('abcde'), 1);
    });

    test('estimate uses CJK multiplier for CJK text', () {
      // Japanese hiragana: あいう (3 chars) → 3*3/4 = 2
      expect(TokenCounter.estimate('あいう'), 2);
      // Chinese chars: 中文测试 (4 chars) → 4*3/4 = 3
      expect(TokenCounter.estimate('中文测试'), 3);
    });

    test('estimate returns 0 for single ASCII char', () {
      expect(TokenCounter.estimate('a'), 0);
    });

    test('addSystem increments system tokens', () {
      final tc = TokenCounter();
      tc.addSystem('You are a helpful assistant.');
      expect(tc.totalTokens, greaterThan(0));
    });

    test('addMessage increments input tokens', () {
      final tc = TokenCounter();
      tc.addMessage('Hello world');
      expect(tc.inputTokens, greaterThan(0));
    });

    test('addOutput increments output tokens', () {
      final tc = TokenCounter();
      tc.addOutput(50);
      expect(tc.outputTokens, equals(50));
      expect(tc.totalTokens, equals(50));
    });

    test('addOutput clamps negative values to zero', () {
      final tc = TokenCounter();
      tc.addOutput(-5);
      expect(tc.outputTokens, equals(0));
    });

    test('addCacheRead increments cache read tokens', () {
      final tc = TokenCounter();
      tc.addCacheRead(200);
      expect(tc.cacheReadTokens, equals(200));
    });

    test('addCacheWrite increments cache write tokens', () {
      final tc = TokenCounter();
      tc.addCacheWrite(100);
      expect(tc.cacheWriteTokens, equals(100));
    });

    test('recordUsage accumulates from all fields', () {
      final tc = TokenCounter();
      tc.recordUsage(
        promptTokens: 100,
        completionTokens: 50,
        cacheReadTokens: 200,
        cacheWriteTokens: 30,
      );
      expect(tc.inputTokens, equals(100));
      expect(tc.outputTokens, equals(50));
      expect(tc.cacheReadTokens, equals(200));
      expect(tc.cacheWriteTokens, equals(30));
      expect(tc.totalTokens, equals(380));
    });

    test('recordUsage ignores non-positive values', () {
      final tc = TokenCounter();
      tc.recordUsage(promptTokens: 0, completionTokens: -5);
      expect(tc.inputTokens, equals(0));
      expect(tc.outputTokens, equals(0));
    });

    test('recordUsage accumulates on top of existing values', () {
      final tc = TokenCounter();
      tc.recordUsage(promptTokens: 100, completionTokens: 50);
      expect(tc.totalTokens, equals(150));
      tc.recordUsage(promptTokens: 10, completionTokens: 5);
      expect(tc.totalTokens, equals(165));
    });

    test('reset clears all buckets including cache', () {
      final tc = TokenCounter();
      tc.addSystem('system prompt');
      tc.addMessage('user message');
      tc.addOutput(50);
      tc.addCacheRead(200);
      tc.addCacheWrite(50);
      expect(tc.totalTokens, greaterThan(0));
      tc.reset();
      expect(tc.totalTokens, equals(0));
      expect(tc.inputTokens, equals(0));
      expect(tc.outputTokens, equals(0));
      expect(tc.cacheReadTokens, equals(0));
      expect(tc.cacheWriteTokens, equals(0));
    });

    test('addCacheRead clamps negative to zero', () {
      final tc = TokenCounter();
      tc.addCacheRead(-10);
      expect(tc.cacheReadTokens, equals(0));
    });

    test('addCacheWrite clamps negative to zero', () {
      final tc = TokenCounter();
      tc.addCacheWrite(-10);
      expect(tc.cacheWriteTokens, equals(0));
    });
  });

  // ── OverflowDetector ───────────────────────────────────────────────────

  group('OverflowDetector', () {
    test('forModel uses provided context length', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.contextLimit, equals(100000));
    });

    test('forModel falls back to 200000 for null context', () {
      final detector = OverflowDetector.forModel(null);
      expect(detector.contextLimit, equals(200000));
    });

    test('forModel falls back to 200000 for non-positive context', () {
      final detector = OverflowDetector.forModel(0);
      expect(detector.contextLimit, equals(200000));
      final detector2 = OverflowDetector.forModel(-100);
      expect(detector2.contextLimit, equals(200000));
    });

    test('forModel calculates reserved buffer as min(20000, limit ~/ 10)', () {
      final detector = OverflowDetector.forModel(300000);
      expect(detector.reservedBuffer, equals(20000));
      final detector2 = OverflowDetector.forModel(50000);
      expect(detector2.reservedBuffer, equals(5000));
    });

    test('forModel uses compactionBuffer when provided', () {
      final detector = OverflowDetector.forModel(
        100000,
        compactionBuffer: 15000,
      );
      expect(detector.reservedBuffer, equals(15000));
    });

    test('usable returns contextLimit - reservedBuffer', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.usable, equals(90000));
    });

    test('isOverflow returns true when totalTokens >= usable', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.isOverflow(89999), isFalse);
      expect(detector.isOverflow(90000), isTrue);
      expect(detector.isOverflow(100000), isTrue);
    });

    test('suggestedMaxOutput returns remaining capacity', () {
      final detector = OverflowDetector.forModel(100000);
      // usable = 90000, maxOutput = 4096
      expect(detector.suggestedMaxOutput(80000), equals(4096));
      // Remaining = 90000 - 89000 = 1000, min(4096, 1000) = 1000
      expect(detector.suggestedMaxOutput(89000), equals(1000));
    });

    test('suggestedMaxOutput returns 0 when overflow', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.suggestedMaxOutput(90000), equals(0));
      expect(detector.suggestedMaxOutput(100000), equals(0));
    });

    test('default constructor uses provided values', () {
      const detector = OverflowDetector(
        contextLimit: 50000,
        maxOutputTokens: 2048,
        reservedBuffer: 5000,
      );
      expect(detector.contextLimit, equals(50000));
      expect(detector.maxOutputTokens, equals(2048));
      expect(detector.reservedBuffer, equals(5000));
      expect(detector.usable, equals(45000));
    });
  });

  // ── AgentRegistry ──────────────────────────────────────────────────────

  group('AgentRegistry', () {
    test('get returns agent by id', () {
      final registry = AgentRegistry();
      final build = registry.get('build');
      expect(build, isNotNull);
      expect(build!.id, equals('build'));
      expect(build.name, equals('Build'));
      expect(build.mode, equals(AgentMode.primary));
    });

    test('get returns null for unknown id', () {
      final registry = AgentRegistry();
      expect(registry.get('nonexistent'), isNull);
    });

    test('getPrimaryAgents returns primary non-hidden agents', () {
      final registry = AgentRegistry();
      final primaries = registry.getPrimaryAgents();
      expect(primaries, isNotEmpty);
      expect(primaries.every((a) => a.mode == AgentMode.primary), isTrue);
      expect(primaries.every((a) => !a.hidden), isTrue);
    });

    test('getSubagents returns subagent non-hidden agents', () {
      final registry = AgentRegistry();
      final subs = registry.getSubagents();
      expect(subs, isNotEmpty);
      expect(subs.every((a) => a.mode == AgentMode.subagent), isTrue);
      expect(subs.every((a) => !a.hidden), isTrue);
    });

    test('getVisibleAgents returns all non-hidden agents', () {
      final registry = AgentRegistry();
      final visible = registry.getVisibleAgents();
      expect(visible, isNotEmpty);
      expect(visible.every((a) => !a.hidden), isTrue);
    });

    test('hidden agents are not in visible list', () {
      final registry = AgentRegistry();
      final visible = registry.getVisibleAgents();
      final hiddenIds = ['compaction', 'title', 'summary'];
      for (final id in hiddenIds) {
        expect(
          visible.any((a) => a.id == id),
          isFalse,
          reason: '$id should be hidden',
        );
      }
    });

    test('hidden agents are accessible via get', () {
      final registry = AgentRegistry();
      expect(registry.get('compaction'), isNotNull);
      expect(registry.get('title'), isNotNull);
      expect(registry.get('summary'), isNotNull);
    });

    test('built-in agents have correct properties', () {
      final registry = AgentRegistry();
      final build = registry.get('build')!;
      expect(build.mode, equals(AgentMode.primary));
      expect(build.maxSteps, isNull);
      expect(build.hidden, isFalse);
      expect(build.systemPrompt, isNotEmpty);

      final explore = registry.get('explore')!;
      expect(explore.mode, equals(AgentMode.subagent));
      expect(explore.maxSteps, isNull);
      expect(explore.hidden, isFalse);

      final general = registry.get('general')!;
      expect(general.mode, equals(AgentMode.subagent));
      expect(general.maxSteps, isNull);
    });

    test('AgentDefinition defaults', () {
      const def = AgentDefinition(id: 'test', name: 'Test');
      expect(def.mode, equals(AgentMode.subagent));
      expect(def.hidden, isFalse);
      expect(def.maxSteps, isNull);
      expect(def.description, isNull);
      expect(def.modelOverride, isNull);
      expect(def.color, isNull);
      expect(def.systemPrompt, isNull);
    });
  });
}
