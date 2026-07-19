import 'package:chatorai/features/models/data/models/model_card_model.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ChatModel _m(String id, String provider) => ChatModel(
  id: id,
  name: id,
  description: id,
  provider: provider,
  contextLength: 4096,
  capabilities: ModelCapabilities(
    reasoning: false,
    multimodal: false,
    vision: false,
    tools: false,
  ),
);

void main() {
  group('ModelState.recentModels', () {
    test('returns empty when no usage recorded', () {
      const state = ModelState(availableModels: []);
      expect(state.recentModels, isEmpty);
    });

    test('ranks by usage count desc', () {
      final models = [_m('a', 'openai'), _m('b', 'openai'), _m('c', 'openai')];
      const state = ModelState(
        availableModels: [],
        usageCounts: {'a': 2, 'b': 5, 'c': 1},
        lastUsed: {'a': 1, 'b': 1, 'c': 1},
      );
      // attach available list via copyWith
      final withModels = state.copyWith(availableModels: models);
      final ids = withModels.recentModels.map((m) => m.id).toList();
      expect(ids, ['b', 'a', 'c']);
    });

    test('ties broken by lastUsed desc', () {
      final models = [_m('a', 'openai'), _m('b', 'openai')];
      final state = const ModelState(
        usageCounts: {'a': 3, 'b': 3},
        lastUsed: {'a': 100, 'b': 200},
      ).copyWith(availableModels: models);
      expect(state.recentModels.map((m) => m.id).toList(), ['b', 'a']);
    });

    test('limits to top 6', () {
      final models = List.generate(10, (i) => _m('m$i', 'openai'));
      final usage = {for (var i = 0; i < 10; i++) 'm$i': i};
      final lastUsed = {for (var i = 0; i < 10; i++) 'm$i': i};
      final state = const ModelState().copyWith(
        availableModels: models,
        usageCounts: usage,
        lastUsed: lastUsed,
      );
      expect(state.recentModels.length, 6);
      expect(state.recentModels.first.id, 'm9');
    });

    test('excludes models no longer available', () {
      final models = [_m('a', 'openai')];
      final state = const ModelState(
        usageCounts: {'a': 5, 'gone': 10},
        lastUsed: {'a': 1, 'gone': 1},
      ).copyWith(availableModels: models);
      expect(state.recentModels.map((m) => m.id).toList(), ['a']);
    });
  });
}
