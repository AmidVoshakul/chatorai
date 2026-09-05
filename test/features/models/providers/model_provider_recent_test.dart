import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/gui/features/models/providers/model_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ModelConfig _m(String id) {
  final parts = id.split('/');
  final providerId = parts.isNotEmpty ? parts.first : 'test';
  final modelName = parts.length > 1 ? parts.sublist(1).join('/') : id;
  return ModelConfig.basic(
    providerId: providerId,
    modelName: modelName,
    displayName: id,
    description: id,
    contextLength: 4096,
  );
}

void main() {
  group('ModelState.recentModels', () {
    test('returns empty when no usage recorded', () {
      const state = ModelState(availableModels: []);
      expect(state.recentModels, isEmpty);
    });

    test('ranks by usage count desc', () {
      final models = [_m('openai/a'), _m('openai/b'), _m('openai/c')];
      final usageCounts = {'openai/a': 2, 'openai/b': 5, 'openai/c': 1};
      final lastUsed = {'openai/a': 1, 'openai/b': 1, 'openai/c': 1};
      final state = ModelState(
        availableModels: models,
        usageCounts: usageCounts,
        lastUsed: lastUsed,
      );
      final ids = state.recentModels.map((m) => m.id.split('/').last).toList();
      expect(ids, ['b', 'a', 'c']);
    });

    test('ties broken by lastUsed desc', () {
      final models = [_m('openai/a'), _m('openai/b')];
      final usageCounts = {for (final m in models) m.id: 3};
      final lastUsed = {'openai/a': 100, 'openai/b': 200};
      final state = ModelState(
        availableModels: models,
        usageCounts: usageCounts,
        lastUsed: lastUsed,
      );
      expect(state.recentModels.map((m) => m.id.split('/').last).toList(), [
        'b',
        'a',
      ]);
    });

    test('limits to top 6', () {
      final models = List.generate(10, (i) => _m('openai/m$i'));
      final usage = {for (final m in models) m.id: models.indexOf(m)};
      final lastUsed = {for (final m in models) m.id: models.indexOf(m)};
      final state = ModelState(
        availableModels: models,
        usageCounts: usage,
        lastUsed: lastUsed,
      );
      expect(state.recentModels.length, 6);
      expect(state.recentModels.first.id.split('/').last, 'm9');
    });

    test('excludes models no longer available', () {
      final models = [_m('openai/a')];
      final usageCounts = {'openai/a': 5, 'openai/gone': 10};
      final lastUsed = {'openai/a': 1, 'openai/gone': 1};
      final state = ModelState(
        availableModels: models,
        usageCounts: usageCounts,
        lastUsed: lastUsed,
      );
      expect(state.recentModels.map((m) => m.id.split('/').last).toList(), [
        'a',
      ]);
    });
  });
}
