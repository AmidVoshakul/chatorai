import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/services/chat_actions.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:chatorai/providers.dart';

// ---------------------------------------------------------------------------
// Test notifiers to control provider state without side effects
// ---------------------------------------------------------------------------

class _TestCurrentAgentNotifier extends CurrentAgentNotifier {
  @override
  AgentDefinition build() => const AgentDefinition(
    id: 'agent-tester',
    name: 'tester',
    mode: AgentMode.primary,
  );
}

class _TestModelNotifier extends ModelNotifier {
  @override
  ModelState build() => const ModelState(selectedModelId: 'model-123');
}

// ---------------------------------------------------------------------------
// Helper widget to obtain a real WidgetRef inside testWidgets
// ---------------------------------------------------------------------------

class _RefBuilder extends ConsumerWidget {
  const _RefBuilder({required this.builder});

  final Widget Function(BuildContext, WidgetRef) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => builder(context, ref);
}

void main() {
  group('ChatActions message factories', () {
    testWidgets('createUserMessage returns correct message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final message = actions.createUserMessage('Hello world');

                expect(message.role, MessageRole.user);
                expect(message.content, 'Hello world');
                expect(message.isComplete, true);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('createUserMessage sets image fields when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final message = actions.createUserMessage(
                  'Check this image',
                  base64Data: 'base64data',
                  imageType: 'image/png',
                );

                expect(message.role, MessageRole.user);
                expect(message.content, 'Check this image');
                expect(message.imageData, 'base64data');
                expect(message.imageType, 'image/png');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('createUserMessage sets imageName when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final message = actions.createUserMessage(
                  'Check this image',
                  base64Data: 'base64data',
                  imageType: 'image/png',
                  imageName: 'photo.png',
                );

                expect(message.imageName, 'photo.png');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
      'createUserMessage leaves image fields null when not provided',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final message = actions.createUserMessage('Text only');

                  expect(message.imageData, isNull);
                  expect(message.imageType, isNull);
                  expect(message.attachedDocPath, isNull);

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets('createUserMessage sets attachedDocPath when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final message = actions.createUserMessage(
                  'See doc',
                  attachedDocPath: '/tmp/doc.pdf',
                );

                expect(message.attachedDocPath, '/tmp/doc.pdf');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
      'createAssistantMessage returns assistant message with default agent from currentAgent',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final message = actions.createAssistantMessage(
                    content: 'Hi',
                    reasoning: 'thinking',
                    tokensInput: 10,
                    tokensOutput: 20,
                  );

                  expect(message.role, MessageRole.assistant);
                  expect(message.content, 'Hi');
                  expect(message.reasoning, 'thinking');
                  expect(message.tokensInput, 10);
                  expect(message.tokensOutput, 20);
                  expect(message.agent, 'tester');

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'createAssistantMessage uses provided agent instead of fallback',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final message = actions.createAssistantMessage(
                    content: 'Hi',
                    agent: 'custom-agent',
                  );

                  expect(message.agent, 'custom-agent');

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'createAssistantMessage falls back to _selectedModelId when model not provided',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final message = actions.createAssistantMessage(content: 'Hi');

                  expect(message.model, isA<String>());
                  expect(message.model, 'model-123');

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets('createAssistantMessage uses provided model when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final message = actions.createAssistantMessage(
                  content: 'Hi',
                  model: 'gpt-4',
                );

                expect(message.model, 'gpt-4');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('createAssistantMessage sets isComplete from argument', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                final incomplete = actions.createAssistantMessage(
                  content: 'partial',
                  isComplete: false,
                );
                final complete = actions.createAssistantMessage(
                  content: 'done',
                  isComplete: true,
                );

                expect(incomplete.isComplete, false);
                expect(complete.isComplete, true);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
      'createAssistantMessage passes through token and context fields',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final message = actions.createAssistantMessage(
                    content: 'Hi',
                    tokensReasoning: 5,
                    tokensCacheRead: 3,
                    tokensCacheWrite: 1,
                    tokensCacheIncludedInInput: true,
                    contextLength: 8192,
                  );

                  expect(message.tokensReasoning, 5);
                  expect(message.tokensCacheRead, 3);
                  expect(message.tokensCacheWrite, 1);
                  expect(message.tokensCacheIncludedInInput, true);
                  expect(message.contextLength, 8192);

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'createAssistantMessage passes through partsJson when provided',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAgentProvider.overrideWith(
                () => _TestCurrentAgentNotifier(),
              ),
              modelProvider.overrideWith(() => _TestModelNotifier()),
            ],
            child: MaterialApp(
              home: _RefBuilder(
                builder: (context, ref) {
                  final actions = ChatActions(ref);
                  final parts = [
                    {'type': 'text', 'text': 'hello'},
                  ];
                  final message = actions.createAssistantMessage(
                    content: 'Hi',
                    partsJson: parts,
                  );

                  expect(message.partsJson, parts);

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------

  group('ChatActions.dispose', () {
    testWidgets('is safe when no session runner is active', (tester) async {
      final actionsHolder = <ChatActions>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(),
            ),
            modelProvider.overrideWith(() => _TestModelNotifier()),
          ],
          child: MaterialApp(
            home: _RefBuilder(
              builder: (context, ref) {
                final actions = ChatActions(ref);
                if (actionsHolder.isEmpty) actionsHolder.add(actions);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(() => actionsHolder.single.dispose(), returnsNormally);
    });
  });
}
