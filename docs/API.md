# API Reference

**Last updated:** 2026-06-28

This document describes the public APIs of ChatORAI for developers, contributors, and advanced users.

## Table of Contents

- [Providers](#providers)
- [Services](#services)
- [Data Models](#data-models)
- [Tools](#tools)
- [Events](#events)
- [Configuration](#configuration)

---

## Providers

All providers are defined using Riverpod 3.x and can be accessed via `ref.watch()` or `ref.read()`.

### Chat Providers

| Provider                   | Type                                                                     | Description                                                                      |
| -------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| `chatListProvider`         | `NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>`             | List of all chats with CRUD operations.                                          |
| `chatScreenProvider`       | `StateNotifierProvider<ChatScreenNotifier, ChatScreenState>`             | UI state for chat screen (streaming, suggestions, sidebar, headings).            |
| `streamingMessageProvider` | `StateNotifierProvider<StreamingMessageNotifier, StreamingMessageState>` | State for the currently streaming assistant message (parts accumulation).        |
| `currentChatIdProvider`    | `NotifierProvider<CurrentChatIdNotifier, String?>`                       | Currently active chat ID (router-level).                                         |
| `currentChatProvider`      | `Provider<Chat?>`                                                        | Computed chat by ID (derived from `currentChatIdProvider` + `chatListProvider`). |

### Model Providers

| Provider        | Type                                               | Description                                                  |
| --------------- | -------------------------------------------------- | ------------------------------------------------------------ |
| `modelProvider` | `StateNotifierProvider<ModelNotifier, ModelState>` | Model selection, favorites, available models from providers. |
| `themeProvider` | `StateNotifierProvider<ThemeNotifier, ThemeState>` | Theme, language, font size, wide screen mode.                |

### Configuration Providers

| Provider                   | Type                                                                     | Description                                                          |
| -------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `configProvider`           | `Provider<ChatOrAIConfig>`                                               | Validated `chatorai.json` configuration.                             |
| `permissionProvider`       | `Provider<PermissionService>`                                            | Permission service instance (singleton).                             |
| `providerSettingsProvider` | `StateNotifierProvider<ProviderSettingsNotifier, ProviderSettingsState>` | Multi-provider configuration (API keys, base URLs, selected models). |

### Core Services

| Provider                        | Type                              | Description                                                         |
| ------------------------------- | --------------------------------- | ------------------------------------------------------------------- |
| `chatAiServiceProvider`         | `Provider<ChatAiService>`         | AI completion service with tool execution loop.                     |
| `sessionRunnerProvider`         | `Provider<SessionRunner>`         | Event-sourced session orchestrator.                                 |
| `sessionRepositoryProvider`     | `Provider<SessionRepository>`     | Session CRUD + event replay.                                        |
| `sessionTreeProvider`           | `Provider<SessionTree>`           | Parent-child session navigation.                                    |
| `chatRepositoryProvider`        | `Provider<ChatRepository>`        | Chat persistence repository.                                        |
| `chatStorageServiceProvider`    | `Provider<ChatStorageService>`    | Local storage abstraction (SharedPreferences).                      |
| `toolRegistryProvider`          | `FutureProvider<ToolRegistry>`    | Registry of all available tools (16 built-in + dynamic skills).     |
| `skillServiceProvider`          | `FutureProvider<SkillService>`    | Skill management service for dynamic capabilities.                  |
| `mcpClientServiceProvider`      | `Provider<McpClientService>`     | MCP server connections for external tool integration.               |
| `lspServiceProvider`           | `Provider<LspService>`           | LSP integration for code intelligence.                              |

---

## Services

### ChatAiService

Core service for AI completions with tool execution. Constructed with a `modelFactory` that creates `Model` instances from model IDs, and optional headers (e.g., OpenRouter auth).

**Key method:**

```dart
Stream<StreamTextEvent> streamChatCompletion({
  required List<Map<String, dynamic>> messages,
  required String model,
  required double temperature,
  required ToolSet tools,
  required void Function(String) onChunk,
  required void Function(String) onReasoning,
  required void Function(ToolStartEvent) onToolStart,
  required void Function(ToolEndEvent) onToolEnd,
  required void Function(ToolError) onToolError,
  required void Function(String) onCompletion,
})
```

**Event types:**

- `Chunk` — text delta
- `Reasoning` — thinking process delta
- `ToolStart` — tool invocation began
- `ToolEnd` — tool completed (with result and duration)
- `ToolError` — tool failed
- `Completion` — turn complete

**Features:**

- Unbounded retry with exponential backoff (base 2s, jitter 30%, cap 30s).
- Respects `Retry-After` headers from rate limits.
- Token counting and overflow detection.
- Cancellation via `CancellationToken` (used by emergency stop).

### PermissionService

Controls tool execution based on user-defined rules from `chatorai.json` and built-in defaults. Evaluates rules using wildcard patterns; last-match-wins; fallback=`ask` when no rule matches.

**Default rules** (defined in `PermissionRuleset.defaults()`, `lib/core/permission/ruleset.dart`):

| Tool               | Default Action |
| ------------------ | -------------- |
| `read`             | `allow`        |
| `glob`             | `allow`        |
| `grep`             | `allow`        |
| `webfetch`         | `allow`        |
| `websearch`        | `allow`        |
| `task`             | `allow`        |
| `question`         | `allow`        |
| `todowrite`        | `allow`        |
| `skill`            | `allow`        |
| `lsp`              | `allow`        |
| `bash`             | `ask`          |
| `edit`             | `ask`          |
| `write`            | `ask`          |
| `doom_loop`        | `ask`          |
| `external_directory` | `ask`        |
| `apply_patch`      | `ask` (fallback — no ruleset entry) |
| `format`           | `ask` (fallback — no ruleset entry) |
| `invalid`          | `ask` (fallback — no ruleset entry) |

**Usage:**

```dart
await permissionService.ask(
  PermissionRequest(
    id: 'unique_id',
    toolName: 'bash',
    permission: 'execute',
    patterns: ['/home/**'],
    metadata: {...},
  ),
  ruleset,
);
```

**Dialog UI:** Once / Always allow / Reject. "Always" promotes to session ruleset.

### ToolRegistry

Registry for all built-in and custom tools. Converts internal `ToolDef` to `ai_sdk_dart` `Tool` via `toSDKTools()`.

**Registration:**

- All built-in tools registered in `built_in_tools.dart` via `registerBuiltInTools()` — 16 unconditional + up to 3 conditional (19 total possible).
- Conditional: `lsp` (when `LspService` is provided), `format` (when `FormatService` is provided), `skill` (when `SkillService` is provided).
- The `task` tool requires `chatAiService`, `toolRegistry`, and `currentSessionRunner` parameters.
- Permission defaults defined in `PermissionRuleset.defaults()` (`lib/core/permission/ruleset.dart`).
- Evaluation uses `evaluate()` from `lib/core/permission/evaluator.dart` — last-match-wins, fallback to `ask`.

### SessionRunner

Orchestrates session lifecycle with event sourcing. Created via `Session跑了.runTaskInChild()` or through `session_providers.dart`.

**Key methods:**

```dart
// Start a new root session
Future<SessionRunnerSession> startSession({
  required String agent,        // 'general', 'explore', 'code-reviewer', etc.
  String? modelRef,             // model identifier from catalog
  String? title,                // optional session title
  String? parentSessionId,      // for hierarchical sessions
})

// Start a pre-initialized session
Future<SessionRunnerSession> startInitializedSession({
  required String agent,
  String? modelRef,
  String? title,
  String? parentSessionId,
})

// Run a task in a child session (delegated subagent work)
Future<void> runTaskInChild({
  required SessionID parentSessionId,
  required String taskPrompt,
  required Future<void> Function(SessionRunnerSession child) streamFn,
  String? agent,
  String? modelRef,
  String? title,
  String? taskId,
  sdk.CancellationToken? abortSignal,
})
```

**Properties of `SessionRunnerSession`:**

```dart
class SessionRunnerSession {
  final SessionID id;
  final SessionID? parentId;
  final String agent;
  final String? modelRef;
  final DateTime createdAt;
}
```

**Usage via Riverpod providers:**

```dart
// In a widget or notifier:
final sessionRunner = ref.read(sessionRunnerProvider);
final session = await sessionRunner.startSession(agent: 'general');
```

**Stream events** from `SessionRunner` are persisted to the `EventStore` and can be replayed via `SessionRepository` to reconstruct `SessionState`.

### CompactionService

Automatically summarizes old messages when token budget is exceeded. Splits messages into head (old) + tail (recent), summarizes head via LLM, and prunes tool outputs older than 2 turns. Already implemented in `lib/core/context/compaction_service.dart`.

Wired into the session pipeline via `CompactionOrchestrator` (`lib/core/context/compaction_orchestrator.dart`), which loads the session state, invokes `CompactionService.compact()`, and persists `CompactionStarted` / `CompactionEnded` events through `SessionRepository`.

### SkillService

Manages dynamic skill discovery and loading. Skills provide specialized instructions and workflows. Used by the `skill` tool and agent system.

---

## Data Models

### Messages

The message system uses a concrete `Message` class (not abstract) with `MessageRole` enum to distinguish user/assistant/system/error messages. For assistant messages, the body is composed of typed `MessagePart` objects stored as `partsJson` (serialized).

**Core classes:**

- `Message` — id, role, content, timestamp, isComplete, isError, model, reasoning, imageData, partsJson, etc.
- `Chat` — id, title, messages, createdAt, updatedAt.
- `MessageRole` — user, assistant, system, error.

**MessageParts** (serialized as JSON with `type` field):

| Part Type        | Description                                                            | Widget                 |
| ---------------- | ---------------------------------------------------------------------- | ---------------------- |
| `TextPart`       | Plain text content                                                     | `TextPartWidget`       |
| `ReasoningPart`  | Model's thinking process (collapsible, with optional duration)         | `ReasoningPartWidget`  |
| `ToolCallPart`   | Tool invocation (toolName, input)                                      | `ToolCallPartWidget`   |
| `ToolResultPart` | Tool output (state, output, duration, error)                           | `ToolResultPartWidget` |
| `TaskPart`       | Delegated subagent task                                                | `TaskPartWidget`       |
| `QuestionPart`   | Multi-question flow awaiting user response                             | `QuestionPartWidget`   |
| `TodoPart`       | Todo list with items                                                   | `TodoPartWidget`       |

**ReasoningPart fields** (defined in `lib/features/chat/data/models/chat/reasoning_part.dart`):

| Field         | Type        | Description                                                 |
| ------------- | ----------- | ----------------------------------------------------------- |
| `content`     | `String`    | The reasoning/thinking text                                 |
| `title`       | `String?`   | Optional display title                                      |
| `isStreaming` | `bool`      | Whether the part is still being streamed                    |
| `startedAt`   | `DateTime?` | When the reasoning started (used to compute `durationMs`)   |
| `durationMs`  | `int?`      | Computed duration in ms (set when streaming ends, persisted) |
| `isExpanded`  | `bool?`     | UI expand/collapse state                                    |

`durationMs` is computed in `StreamingMessageNotifier._markReasoningAsDone()` and `stopStreaming()` when reasoning streaming ends. It is persisted via `toJson()`/`fromJson()` and survives chat switches and app reloads. The `ReasoningPartWidget._displayDuration` getter prefers `widget.part.durationMs` over a locally computed `_thoughtDuration`.

**Note:** `ApplyPatchPart` and `SkillPart` are not implemented message part types. The `apply_patch` tool outputs via `ToolResultPartWidget` like any other tool.

---

## Tools

All tools implement the `Tool` interface from `ai_sdk_dart`. The `ToolRegistry` converts internal `ToolDef` implementations to SDK tools.

### Built-in Tools (19 total, 16 unconditional + 3 conditional)

**Always registered (16):**

| Tool                | Description                                                   | Input Schema                                                                       | Default Permission |
| ----------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------ |
| `bash`             | Execute shell command                                         | `{ "command": string, "timeoutMs": number }`                                       | ask                |
| `read`             | Read file contents                                            | `{ "path": string, "offset": number, "limit": number }`                            | allow              |
| `edit`             | Replace text in file                                          | `{ "path": string, "oldString": string, "newString": string }`                     | ask                |
| `write`            | Create/overwrite file                                         | `{ "path": string, "content": string }`                                            | ask                |
| `glob`             | Find files by pattern                                         | `{ "pattern": string, "path": string }`                                            | allow              |
| `grep`             | Search file contents                                          | `{ "pattern": string, "path": string, "filePattern": string }`                     | allow              |
| `webfetch`         | Fetch URL content                                             | `{ "url": string, "format": "text" \| "markdown" \| "html" }`                      | allow              |
| `websearch`        | Search web via SearXNG                                        | `{ "query": string, "engines": string[], "categories": string[] }`                 | allow              |
| `task`             | Spawn subagent via `SessionRunner`                            | `{ "prompt": string, "context": object, "subagentType": string }`                  | allow              |
| `todowrite`        | Update todo list                                              | `{ "todos": [{ "content": string, "status": "pending"/"completed" }] }`            | allow              |
| `question`         | Ask user question (with dedup)                                | `{ "question": string, "options": string[], "multiple": bool }`                    | allow              |
| `skill`            | Load specialized skill                                        | `{ "name": string, "params": object }`                                             | allow              |
| `apply_patch`      | Apply unified diff                                            | `{ "patch": string, "dryRun": bool }`                                              | ask                |
| `invalid`          | Invalid tool placeholder                                      | `{}`                                                                               | ask                |

**Conditionally registered (up to 3):**

| Tool                         | Condition                                            | Default Permission |
| ---------------------------- | ---------------------------------------------------- | ------------------ |
| `lsp`                        | When `LspService` is provided                        | allow              |
| `format`                     | When `FormatService` is provided                     | ask                |
| `skill` (dynamic loading)    | When `SkillService` is provided                      | allow              |

**Additional tools** (also always registered, listed separately for clarity):

| Tool                   | Description                                       | Default Permission |
| ---------------------- | ------------------------------------------------- | ------------------ |
| `external_directory`   | Directory operations (builtin)                     | ask                |
| `plan_exit`            | Exit plan mode, switch to build agent              | ask                |
| `json_schema`          | JSON schema validation                            | ask (fallback)     |

The actual registration in `registerBuiltInTools()` (see `lib/core/tools/built_in/built_in_tools.dart`) registers 16 tools unconditionally, plus up to 3 conditional tools (`lsp`, `format`, `skill`). Total: 19 possible built-in tools.

**Note:** All tool outputs are truncated to 2000 lines or 50KB when displayed.

---

## Events

### Stream Events

Streamed from `ChatAiService.streamChatCompletion()` (legacy pipeline):

| Event        | Callback                      | Payload                            |
| ------------ | ----------------------------- | ---------------------------------- |
| `Chunk`      | `onChunk(String)`             | Text delta appended to message.    |
| `Reasoning`  | `onReasoning(String)`         | Thinking process delta.            |
| `ToolStart`  | `onToolStart(ToolStartEvent)` | Tool invoked (id, name, input).    |
| `ToolEnd`    | `onToolEnd(ToolEndEvent)`     | Tool completed (result, duration). |
| `ToolError`  | `onToolError(ToolError)`      | Tool failed (error, isEOF).        |
| `Completion` | `onCompletion(String)`        | Final message ID / turn complete.  |

### Session Events (Event Sourcing)

Persisted to Drift `events` table. All events extend `sealed class SessionEvent`:

| Event Type                  | Purpose                                                    |
| --------------------------- | ---------------------------------------------------------- |
| `SessionCreated`            | New session with optional parent, title, agent, model.     |
| `SessionArchived`           | Session archived (soft delete).                            |
| `SessionAgentSwitched`      | Agent changed mid-session.                                  |
| `SessionModelSwitched`      | Model reference changed.                                   |
| `MessageAdded`              | User/assistant/system message persisted.                   |
| `TextStarted/Delta/Ended`   | Assistant streaming text lifecycle.                        |
| `ReasoningStarted/Delta/Ended` | Reasoning/thinking stream lifecycle.                    |
| `ToolInputStarted/Delta/Ended` | Tool JSON input streaming (for progress UI).            |
| `ToolCalled`                | Tool invoked with full input.                              |
| `ToolSuccess`               | Tool completed (output, duration).                         |
| `ToolFailed`                | Tool failed (error message).                               |
| `StepStarted/Ended/Failed`  | Turn lifecycle with token tracking.                        |
| `CompactionStarted/Ended`   | Context compaction with summary.                           |
| `ChildSessionCreated`       | Parent-child session hierarchy.                            |
| `TaskStarted/Completed`     | Delegated subagent task tracking.                           |

---

## Configuration

### chatorai.json Schema

Location resolved via `XdgPaths.configHome` (see `lib/shared/utils/xdg_paths.dart`):

1. `<configHome>/chatorai.json` (user-global, highest priority)
2. Project root `chatorai.json` (fallback)

Typical paths: `~/.config/<package>/chatorai.json` (Linux), `~/Library/Application Support/<package>/chatorai.json` (macOS), `%APPDATA%\<package>\config\chatorai.json` (Windows).

Validated against JSON Schema in `lib/core/config/chatorai_schema.dart`.

**Top-level sections:**

```json5
{
  "version": 1,
  "permission": {
    "default": "ask",
    "rules": [
      { "tool": "read", "action": "*", "resource": "*", "permission": "allow" },
      { "tool": "bash", "action": "execute", "resource": "/home/**", "permission": "deny" }
    ]
  },
  "keybinding": {
    "leader": "ctrl+x",
    "timeout": 2000,
    "bindings": { "session_child_next": "ctrl+right" }
  },
  "skills": {
    "paths": [".opencode/skills/"],
    "urls": []
  },
  "compaction": { "auto": true, "prune": true },
  "formatter": { "formatters": {} },
  "mcp": {
    "default_timeout": 30000,
    "servers": {
      "my-server": {
        "type": "local",
        "command": "npx",
        "args": ["-y", "my-mcp-server"]
      }
    }
  }
}
```

### Environment Variables (.env)

Development only (gitignored, not in release builds):

```env
# Required for development API access
OPENROUTER_API_KEY=your_key_here

# Optional overrides
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
CHATORAI_DEBUG=true
```

---

## Internal APIs (Subject to Change)

- `ChatStorageService`: `getChats()`, `getChat(id)`, `addChat()`, `updateChat()`, `deleteChat()`, etc.
- `SessionRunner`: `startSession()`, `startInitializedSession()`, `runTaskInChild()` — orchestrates session lifecycle with event sourcing.
- `SessionRepository`: CRUD operations for sessions; event replay.
- `SessionTree`: Parent-child navigation in the session hierarchy.
- `EventStore`: `append()`, `read()`, `stream()` on the Drift event store.
- `McpClientService`: `initialize(config)`, `connect(serverName)`, `callTool(...)`, `listAllTools()`, `getToolDefs()`, `disconnect()`, `dispose()`.
- `ModelNotifier`: Manages model selection, favorites, and available models.
- `PermissionRuleset`: `fromConfig(map)`, `defaults()`, merge via `PermissionEvaluator`.
- `ToolExecutor`: `execute(def, input, options)` — cache, doom-loop guard, permission check, truncation.
- `TruncationService`: Singleton, `output(content)` → truncated content + outputPath.
- `SessionState`: Freezed immutable model for session state reconstruction from events.
- `SessionMessage`: Freezed model with JSON serialization, `SessionIDConverter`, `MessageRole`, Equatable mixin.

---

For command-line usage and slash commands, see `docs/COMMANDS.md`.  
For environment setup, see `docs/ENVIRONMENT.md`.  
For architecture overview, see `ARCHITECTURE.md`.
