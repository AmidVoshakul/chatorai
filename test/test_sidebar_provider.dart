import 'dart:async';

import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/sessions/providers/sidebar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  group('SidebarNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(sidebarProvider);
      expect(state.searchQuery, '');
      expect(state.isSearching, false);
    });

    test('setSearchQuery updates search query', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('test');

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, 'test');
      expect(state.isSearching, true);
    });

    test('clearSearch resets search state', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('test');
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.clearSearch();

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, '');
      expect(state.isSearching, false);
    });

    test('search query is case insensitive', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('TEST');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, 'TEST');
    });
  });

  group('SidebarState', () {
    test('copyWith creates new instance with updated values', () {
      const state = SidebarState();
      final newState = state.copyWith(searchQuery: 'test', isSearching: true);

      expect(newState.searchQuery, 'test');
      expect(newState.isSearching, true);
    });

    test('copyWith preserves original values when not specified', () {
      const state = SidebarState(searchQuery: 'original', isSearching: true);
      final newState = state.copyWith(searchQuery: 'updated');

      expect(newState.searchQuery, 'updated');
      expect(newState.isSearching, true);
    });
  });

  group('chatListLoadingProvider', () {
    late ProviderContainer container;

    ProviderContainer buildContainer({bool hangLoad = false}) {
      final mock = _MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      if (hangLoad) {
        when(
          () => mock.findAll(),
        ).thenAnswer((_) => Completer<List<SessionState>>().future);
      } else {
        when(() => mock.findAll()).thenAnswer((_) async => <SessionState>[]);
      }
      return ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
    }

    setUp(() {
      container = buildContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns true when chat list is loading', () {
      container.dispose();
      container = buildContainer(hangLoad: true);
      addTearDown(container.dispose);

      final isLoading = container.read(chatListLoadingProvider);
      expect(isLoading, true);
    });

    test('returns false after chat list finishes loading', () async {
      for (var i = 0; i < 50; i++) {
        if (!container.read(chatListLoadingProvider)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final isLoading = container.read(chatListLoadingProvider);
      expect(isLoading, false);
    });
  });
}
