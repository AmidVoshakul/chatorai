import 'dart:isolate';

import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/session/database.dart' as db;
import 'package:chatorai/core/session/event_store.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_db_provider.dart'
    show sessionRepositoryProvider;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart'
    show sessionStateToChat, messageToChatMessage;
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// RETRY COUNTDOWN PROVIDER
// ===========================================================================

/// Emits a progress value (1.0 → 0.0) during retry backoff waits.
/// Null when not retrying, 0.0 when idle.
final retryCountdownProvider = StreamProvider.autoDispose<double>((ref) {
  final aiService = ref.watch(chatAiServiceProvider);
  return aiService.retryCountdown;
});

/// Emits the current retry message each time backoff begins / countdown resets.
/// Empty string when idle (no retry in progress).
final retryMessageProvider = StreamProvider.autoDispose<String>((ref) {
  final aiService = ref.watch(chatAiServiceProvider);
  return aiService.retryMessageStream;
});

// ===========================================================================
// SERVICE PROVIDERS
// ===========================================================================

final chatAiServiceProvider = Provider<ChatAiService>((ref) {
  // The synchronous catalog is available from the first frame (built-in models
  // work before API keys are preloaded), so this must NOT throw while the
  // catalog is still warming — otherwise the early-mounted ChatScreen would
  // crash/loop.
  //
  // Deliberately NOT watching catalogInitializationProvider: the catalog is a
  // single shared instance that warms in place (preloadApiKeys fills its key
  // cache), and ModelResolver reads keys via the async getApiKey() at request
  // time (with a secure-storage fallback). Rebuilding this provider when the
  // warm future settles would dispose() the previous service — cancelling the
  // in-flight abort token and aborting a request already streaming on it
  // (the mid-stream disposal race). The service is therefore built once and
  // stays stable across warm completion.
  final catalog = ref.watch(providerCatalogServiceProvider);

  final resolver = ModelResolver(catalog);
  final service = ChatAiService(resolver: resolver);
  ref.onDispose(() => service.dispose());
  return service;
});

// ===========================================================================
// CHAT LIST PROVIDER
// ===========================================================================

final chatListProvider =
    NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>(
      ChatListNotifier.new,
    );

// ===========================================================================
// CHAT LIST NOTIFIER
// ===========================================================================

class ChatListNotifier extends Notifier<AsyncValue<List<Chat>>> {
  bool _isLoadingChats = false;
  bool _hasLoadedOnce = false;
  Future<void>? _loadFuture;
  final Set<String> _loadedDetailIds = {};
  final Map<String, Future<Chat?>> _detailLoads = {};
  final Map<String, int> _detailGenerations = {};

  @override
  AsyncValue<List<Chat>> build() {
    // Only start loading if we haven't loaded yet
    if (!_hasLoadedOnce) {
      _loadFuture = _loadChats();
      return const AsyncValue.loading();
    }
    // Return current state if already loaded
    return state;
  }

  Future<void> _loadChats() async {
    // If already loading, wait for the existing load to complete
    if (_isLoadingChats && _loadFuture != null) {
      await _loadFuture;
      return;
    }

    if (_hasLoadedOnce) {
      return;
    }

    _isLoadingChats = true;
    try {
      final repository = await ref.read(sessionRepositoryProvider.future);
      if (!ref.mounted) return;
      // Clean up any orphan sessions (empty title + zero messages) that
      // may have been created by the duplicate-session bug in prior runs.
      final orphans = await repository.cleanupOrphanSessions();
      if (!ref.mounted) return;
      if (orphans > 0) {
        LogTags.chatService.logWarning('Cleaned up $orphans orphan sessions');
      }
      final sessions = await repository.findAll();
      if (!ref.mounted) return;
      final primarySessions = sessions
          .where((s) => s.parentId == null)
          .toList();
      final chats = primarySessions.map(sessionStateToChat).toList();
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncValue.data(chats);
      _hasLoadedOnce = true;
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingChats = false;
      _loadFuture = null;
    }
  }

  Future<void> loadChats({bool forceReload = false}) async {
    if (forceReload) {
      _hasLoadedOnce = false;
      _loadedDetailIds.clear();
      _detailLoads.clear();
    }
    await _loadChats();
  }

  Future<Chat> createNewChat({String? directory}) async {
    // Wait for initial load to complete if not already loaded
    // This prevents race condition where new chat gets overwritten
    if (!_hasLoadedOnce) {
      await _loadChats();
    }

    final repository = await ref.read(sessionRepositoryProvider.future);
    final sessionState = await repository.createSession(
      title: '',
      agent: 'general',
      directory: directory ?? workspaceRuntimeCurrent.path,
    );
    final newChat = sessionStateToChat(sessionState);
    _loadedDetailIds.add(newChat.id);

    // Get current state AFTER load completes
    final currentState = state;
    if (currentState.hasValue) {
      final chats = currentState.value!;
      state = AsyncValue.data([newChat, ...chats]);
    } else if (currentState.isLoading) {
      // This should not happen after waiting for load
      state = AsyncValue.data([newChat]);
    } else if (currentState.hasError) {
      // If there was an error, start with the new chat
      state = AsyncValue.data([newChat]);
    }

    return newChat;
  }

  Future<void> deleteChat(String chatId) async {
    final repository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = SessionID.fromString(chatId);
    await repository.deleteSession(sessionId);
    _loadedDetailIds.remove(chatId);
    _detailLoads.remove(chatId);
    _detailGenerations.remove(chatId);
    state.whenData((chats) {
      state = AsyncValue.data(chats.where((c) => c.id != chatId).toList());
    });
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    final repository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = SessionID.fromString(chatId);
    await repository.appendEvent(
      SessionTitleUpdated(
        sessionId: sessionId,
        title: newTitle,
        timestamp: DateTime.now(),
      ),
    );
    state.whenData((chats) {
      state = AsyncValue.data(
        chats.map((c) {
          if (c.id == chatId) {
            return c.copyWith(title: newTitle, updatedAt: DateTime.now());
          }
          return c;
        }).toList(),
      );
    });
  }

  void updateChat(Chat updatedChat) {
    final currentState = state;

    if (currentState.hasValue) {
      final chats = currentState.value!;
      final index = chats.indexWhere((c) => c.id == updatedChat.id);
      if (index >= 0) {
        final newChats = List<Chat>.from(chats);
        newChats[index] = updatedChat;
        state = AsyncValue.data(newChats);
      } else {
        state = AsyncValue.data([updatedChat, ...chats]);
      }
    } else if (currentState.isLoading) {
      state = AsyncValue.data([updatedChat]);
    } else if (currentState.hasError) {
      state = AsyncValue.data([updatedChat]);
    }
  }

  static const int _inlineBuildThreshold = 2000;

  /// Returns `true` when the chat should be built on the main isolate instead
  /// of being dispatched to a background isolate. Small histories are cheaper
  /// to decode synchronously than the isolate spin-up cost.
  static bool shouldBuildInline(int rowCount) =>
      rowCount <= _inlineBuildThreshold;

  /// Pure, isolate-safe: decodes durable event rows, replays them into a
  /// [SessionState], and converts to a full [Chat]. Falls back to the
  /// metadata [Chat] when the session has no messages. Row order is guaranteed
  /// by the SQL query; no local sort is required.
  static Chat _buildChatFromEventRows(List<db.Event> rows, Chat metadata) {
    if (rows.isEmpty) return metadata;
    final events = rows.map(EventStore.deserializeEvent).toList();
    final state = replayEvents(events);
    if (state.messages.isEmpty) return metadata;
    return sessionStateToChat(state);
  }

  /// Lazily loads full message history for a single chat, replacing the
  /// metadata-only entry in the list. Single-flight: concurrent calls for the
  /// same [chatId] share one in-flight future.
  Future<Chat?> ensureChatLoaded(String chatId, {bool forceRefresh = false}) {
    if (forceRefresh) {
      _loadedDetailIds.remove(chatId);
      _detailLoads.remove(chatId);
      _detailGenerations[chatId] = (_detailGenerations[chatId] ?? 0) + 1;
    }
    final inFlight = _detailLoads[chatId];
    if (inFlight != null) return inFlight;
    final future = _ensureChatLoadedInner(chatId, forceRefresh: forceRefresh);
    _detailLoads[chatId] = future;
    future.whenComplete(() => _detailLoads.remove(chatId));
    return future;
  }

  Future<Chat?> _ensureChatLoadedInner(
    String chatId, {
    bool forceRefresh = false,
  }) async {
    final current = state.whenOrNull(
      data: (chats) {
        try {
          return chats.firstWhere((c) => c.id == chatId);
        } catch (_) {
          return null;
        }
      },
    );
    if (current == null) return null;
    if (!forceRefresh &&
        (_loadedDetailIds.contains(chatId) || current.messages.isNotEmpty)) {
      return current;
    }
    final expectedGeneration = _detailGenerations[chatId] ?? 0;
    final repository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = SessionID.fromString(chatId);

    // Try snapshot cache first (unless forceRefresh bypasses it).
    if (!forceRefresh) {
      final snapshotStopwatch = Stopwatch()..start();
      final snapshotMessages = await repository.readChatSnapshot(sessionId);
      snapshotStopwatch.stop();
      if (snapshotMessages != null) {
        LogTags.chatService.logDebug(
          '[ChatList] snapshot chat=$chatId messages=${snapshotMessages.length} read=${snapshotStopwatch.elapsedMilliseconds}ms',
        );
        final chat = _chatFromSnapshotMessages(
          chatId,
          snapshotMessages,
          current,
        );
        if (!ref.mounted) return null;
        if ((_detailGenerations[chatId] ?? 0) != expectedGeneration) {
          return null;
        }
        final stillExists = state.whenOrNull(
          data: (chats) => chats.any((c) => c.id == chatId),
        );
        if (stillExists != true) return null;
        _loadedDetailIds.add(chatId);
        updateChat(chat);
        return chat;
      }
    }

    final queryStopwatch = Stopwatch()..start();
    final rows = await repository.getEventRowsForSessions([sessionId]);
    queryStopwatch.stop();
    LogTags.chatService.logDebug(
      '[ChatList] query chat=$chatId rows=${rows.length} query=${queryStopwatch.elapsedMilliseconds}ms',
    );
    if (!ref.mounted) return null;
    final buildStopwatch = Stopwatch()..start();
    final Chat chat;
    if (shouldBuildInline(rows.length)) {
      chat = _buildChatFromEventRows(rows, current);
      buildStopwatch.stop();
      LogTags.chatService.logDebug(
        '[ChatList] build chat=$chatId build=${buildStopwatch.elapsedMilliseconds}ms mode=inline',
      );
    } else {
      chat = await Isolate.run(() => _buildChatFromEventRows(rows, current));
      buildStopwatch.stop();
      LogTags.chatService.logDebug(
        '[ChatList] build chat=$chatId build=${buildStopwatch.elapsedMilliseconds}ms mode=isolate',
      );
    }
    LogTags.chatService.logDebug(
      '[ChatList] total chat=$chatId total=${queryStopwatch.elapsedMilliseconds + buildStopwatch.elapsedMilliseconds}ms',
    );
    if (!ref.mounted) return null;
    if ((_detailGenerations[chatId] ?? 0) != expectedGeneration) return null;
    final stillExists = state.whenOrNull(
      data: (chats) => chats.any((c) => c.id == chatId),
    );
    if (stillExists != true) return null;
    _loadedDetailIds.add(chatId);
    updateChat(chat);

    // Write snapshot after successful build (best-effort, do not fail the load).
    try {
      final snapshotMessages = chat.messages.map(messageToChatMessage).toList();
      await repository.writeChatSnapshot(sessionId, snapshotMessages);
    } catch (_) {
      // Snapshot write failure is non-fatal; the next load will replay events.
    }

    return chat;
  }

  static Chat _chatFromSnapshotMessages(
    String chatId,
    List<ChatMessage> snapshotMessages,
    Chat metadata,
  ) {
    if (snapshotMessages.isEmpty) return metadata;
    final messages = snapshotMessages.map(_chatMessageToMessage).toList();
    return Chat(
      id: chatId,
      title: metadata.title,
      messages: messages,
      createdAt: metadata.createdAt,
      updatedAt: metadata.updatedAt,
      compactedContext: metadata.compactedContext,
    );
  }

  static Message _chatMessageToMessage(ChatMessage cm) {
    if (cm is UserMessage) {
      return Message(
        id: cm.id,
        role: MessageRole.user,
        content: cm.content,
        timestamp: cm.timestamp,
        imageData: cm.imageData,
        imageType: cm.imageType,
        attachedDocPath: cm.attachedDocPath,
        isComplete: true,
      );
    }
    if (cm is AssistantMessage) {
      return Message(
        id: cm.id,
        role: MessageRole.assistant,
        content: cm.parts
            .whereType<TextPart>()
            .map((p) => p.content)
            .join('\n'),
        timestamp: cm.timestamp,
        model: cm.model,
        isComplete: true,
        isCompactionSummary: cm.isCompactionSummary,
        partsJson: cm.parts.map((p) => p.toJson()).toList(),
        tokensInput: cm.tokensInput,
        tokensOutput: cm.tokensOutput,
        tokensReasoning: cm.tokensReasoning,
        contextLength: cm.contextLength,
        agent: cm.agent,
      );
    }
    if (cm is SystemMessage) {
      return Message(
        id: cm.id,
        role: MessageRole.system,
        content: cm.content,
        timestamp: cm.timestamp,
        isComplete: true,
      );
    }
    // ErrorMessage or unknown fallback.
    return Message(
      id: cm.id,
      role: MessageRole.assistant,
      content: cm is ErrorMessage ? cm.content : 'Unknown',
      timestamp: cm.timestamp,
      isComplete: true,
      isError: true,
    );
  }
}

// ===========================================================================
// CURRENT CHAT ID STATE
// ===========================================================================

class CurrentChatIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setChatId(String? chatId) {
    state = chatId;
  }

  void clearChatId() {
    state = null;
  }
}

final currentChatIdProvider = NotifierProvider<CurrentChatIdNotifier, String?>(
  CurrentChatIdNotifier.new,
);

// ===========================================================================
// CURRENT CHAT PROVIDER
// ===========================================================================

final currentChatProvider = Provider<Chat?>((ref) {
  final chatId = ref.watch(currentChatIdProvider);
  final chatsAsync = ref.watch(chatListProvider);

  if (chatId == null) return null;

  return chatsAsync.when(
    data: (chats) {
      try {
        return chats.firstWhere((c) => c.id == chatId);
      } catch (_) {
        return null;
      }
    },
    loading: () {
      try {
        final currentChats = chatsAsync.value;
        if (currentChats != null) {
          return currentChats.firstWhere((c) => c.id == chatId);
        }
      } catch (_) {}
      return null;
    },
    error: (e, st) {
      try {
        final currentChats = chatsAsync.value;
        if (currentChats != null) {
          return currentChats.firstWhere((c) => c.id == chatId);
        }
      } catch (_) {}
      return null;
    },
  );
});
