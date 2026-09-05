import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_stack.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/presentation/screens/child_session_screen.dart';
import 'package:chatorai/features/sessions/providers/session_parts_provider.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

/// Yields a minimal empty SessionState so every page renders the
/// "noChatsYet" path without touching the event store.
class _EmptySessionPartsNotifier extends SessionPartsNotifier {
  _EmptySessionPartsNotifier(String sessionId) : super(sessionId);

  @override
  Stream<SessionState> build() async* {
    yield SessionState(
      id: SessionID.fromString(sessionId),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }
}

class _SeededStackNotifier extends SessionStackNotifier {
  final SessionStackState initialState;

  _SeededStackNotifier(this.initialState);

  @override
  SessionStackState build() => initialState;
}

SessionState _session(String id, {String? parentId, String title = ''}) {
  return SessionState(
    id: SessionID.fromString(id),
    parentId: parentId == null ? null : SessionID.fromString(parentId),
    title: title,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

MockSessionRepository _mockRepo({
  required String parentId,
  required List<String> siblingIds,
  Map<String, String> titles = const {},
}) {
  final mock = MockSessionRepository();
  when(() => mock.getSessionMetaFromId(any())).thenAnswer((invocation) async {
    final id = invocation.positionalArguments.single as String;
    return _session(id, parentId: parentId, title: titles[id] ?? '');
  });
  when(() => mock.getChildSessionsFromId(parentId)).thenAnswer(
    (_) async => [
      for (final id in siblingIds) _session(id, parentId: parentId),
    ],
  );
  return mock;
}

IconButton _arrowButton(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
  );
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required MockSessionRepository repo,
  required String sessionId,
  SessionStackState stackSeed = const SessionStackState(),
}) async {
  final container = ProviderContainer(
    overrides: [
      sessionRepositoryProvider.overrideWith((ref) async => repo),
      sessionPartsProvider.overrideWith2(
        (id) => _EmptySessionPartsNotifier(id),
      ),
      sessionStackProvider.overrideWith(() => _SeededStackNotifier(stackSeed)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChildSessionScreen(sessionId: sessionId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionID.create());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChildSessionScreen sibling navigation', () {
    testWidgets(
      'REGRESSION: buttons work when stack holds only the child entry',
      (tester) async {
        final repo = _mockRepo(
          parentId: 'ses_p1',
          siblingIds: ['ses_c1', 'ses_c2', 'ses_c3'],
          titles: {'ses_c1': 'First', 'ses_c2': 'Second', 'ses_c3': 'Third'},
        );
        final container = await _pumpScreen(
          tester,
          repo: repo,
          sessionId: 'ses_c1',
          stackSeed: SessionStackState(stack: [SessionID.fromString('ses_c1')]),
        );

        expect(find.text('1 of 3'), findsOneWidget);
        expect(find.text('First'), findsOneWidget);
        // canGoUp is DB truth: parent known even though the stack has no
        // parent entry (old code wrongly required stack.hasParent).
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_right));
        await tester.pumpAndSettle();
        expect(find.text('2 of 3'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
        expect(container.read(sessionStackProvider).current!.value, 'ses_c2');

        await tester.tap(find.byIcon(Icons.arrow_right));
        await tester.pumpAndSettle();
        expect(find.text('3 of 3'), findsOneWidget);
        expect(container.read(sessionStackProvider).current!.value, 'ses_c3');

        await tester.tap(find.byIcon(Icons.arrow_left));
        await tester.pumpAndSettle();
        expect(find.text('2 of 3'), findsOneWidget);
        expect(container.read(sessionStackProvider).current!.value, 'ses_c2');
        expect(container.read(sessionStackProvider).stack, hasLength(1));
      },
    );

    testWidgets('buttons enable/disable at first, middle and last positions', (
      tester,
    ) async {
      final repo = _mockRepo(
        parentId: 'ses_p1',
        siblingIds: ['ses_c1', 'ses_c2', 'ses_c3'],
      );
      await _pumpScreen(tester, repo: repo, sessionId: 'ses_c1');

      expect(_arrowButton(tester, Icons.arrow_left).onPressed, isNull);
      expect(_arrowButton(tester, Icons.arrow_right).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();
      expect(_arrowButton(tester, Icons.arrow_left).onPressed, isNotNull);
      expect(_arrowButton(tester, Icons.arrow_right).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();
      expect(_arrowButton(tester, Icons.arrow_left).onPressed, isNotNull);
      expect(_arrowButton(tester, Icons.arrow_right).onPressed, isNull);
    });

    testWidgets('horizontal drag flips to the next sibling', (tester) async {
      final repo = _mockRepo(
        parentId: 'ses_p1',
        siblingIds: ['ses_c1', 'ses_c2'],
        titles: {'ses_c1': 'First', 'ses_c2': 'Second'},
      );
      await _pumpScreen(tester, repo: repo, sessionId: 'ses_c1');

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('unknown current id starts at page 0 with prev disabled', (
      tester,
    ) async {
      final repo = _mockRepo(
        parentId: 'ses_p1',
        siblingIds: ['ses_c1', 'ses_c2', 'ses_c3'],
      );
      await _pumpScreen(tester, repo: repo, sessionId: 'ses_unknown');

      expect(find.text('1 of 3'), findsOneWidget);
      expect(_arrowButton(tester, Icons.arrow_left).onPressed, isNull);
      expect(_arrowButton(tester, Icons.arrow_right).onPressed, isNotNull);
    });

    testWidgets('desynced stack is left untouched while navigation works', (
      tester,
    ) async {
      final repo = _mockRepo(
        parentId: 'ses_p1',
        siblingIds: ['ses_c1', 'ses_c2', 'ses_c3'],
      );
      final container = await _pumpScreen(
        tester,
        repo: repo,
        sessionId: 'ses_c1',
        stackSeed: SessionStackState(stack: [SessionID.fromString('ses_zzz')]),
      );

      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3'), findsOneWidget);
      final stack = container.read(sessionStackProvider);
      expect(stack.current!.value, 'ses_zzz');
      expect(stack.stack, hasLength(1));
    });
  });
}
