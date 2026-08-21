# API Reference

**Last updated:** 2026-08-21

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

| Provider                | Type                                                         | Description                                                                      |
| ----------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| `chatListProvider`      | `NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>` | List of all chats with CRUD operations.                                          |
| `chatScreenProvider`    | `NotifierProvider<ChatScreenNotifier, ChatScreenState>`      | UI state for chat screen (streaming, suggestions, sidebar, headings).            |
| `sessionPartsProvider`  | `StreamProvider.family<SessionState, String>`                | Live session state (parts accumulation) for a given session ID.                  |
| `sessionContextUsageProvider` | `Provider<SessionContextUsage>` | Aggregated context usage (tokens, cache, spent USD, instruction sources) for the current chat. |
| `currentChatIdProvider` | `NotifierProvider<CurrentChatIdNotifier, String?>`           | Currently active chat ID (router-level).                                         |
| `currentChatProvider`   | `Provider<Chat?>`                                            | Computed chat by ID (derived from `currentChatIdProvider` + `chatListProvider`). |

### Model Providers

| Provider        | Type                                          | Description                                                                                                  |
| --------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `modelProvider` | `NotifierProvider<ModelNotifier, ModelState>` | Model selection, favorites, usage tracking (`usageCounts`/`lastUsed`), available models, and `recentModels`. |
| `themeProvider` | `NotifierProvider<ThemeNotifier, ThemeState>` | Theme, language, font size, wide screen mode.                                                                |

### Configuration Providers

| Provider             | Type                          | Description                              |
| -------------------- | ----------------------------- | ---------------------------------------- |
| `configProvider`     | `Provider<ChatOrAIConfig>`    | Validated `chatorai.json` configuration. |
| `permissionProvider` | `Provider<PermissionService>` | Permission service instance (singleton). |

### Core Services

| Provider                    | Type                           | Description                                                     |
| --------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `chatAiServiceProvider`     | `Provider<ChatAiService>`      | AI completion service with tool execution loop.                 |
| `sessionRunnerProvider`     | `Provider<SessionRunner>`      | Event-sourced session orchestrator.                             |
| `sessionRepositoryProvider` | `Provider<SessionRepository>`  | Session CRUD + event replay.                                    |
| `sessionTreeProvider`       | `Provider<SessionTree>`        | Parent-child session navigation.                                |
| `toolRegistryProvider`      | `FutureProvider<ToolRegistry>` | Registry of all available tools (21 built-in + dynamic skills + MCP tools). |
| `skillServiceProvider`      | `FutureProvider<SkillService>` | Skill management service for dynamic capabilities.              |
| `mcpClientServiceProvider`  | `Provider<McpClientService>`   | MCP server connections for external tool integration.           |
| `lspServiceProvider`        | `Provider<LspService>`         | LSP integration for code intelligence.                          |

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

- Unbounded retry with exponential backoff (base 500ms, factor 2.0, cap 24h).
- Respects `Retry-After` headers from rate limits.
- Token counting and overflow detection.
- Cancellation via `CancellationToken` (used by emergency stop).

### Link Launcher Utility

`lib/shared/utils/link_launcher.dart` — pure business logic for validating and opening external links.

```dart
bool isHttpHttpsUrl(String? raw);
enum LinkLaunchResult { opened, invalidScheme, failed }
Future<LinkLaunchResult> launchExternalLink(
  String href, {
  Future<bool> Function(Uri uri, {LaunchMode mode})? launcher,
});
```

`isHttpHttpsUrl` returns `true` only for non-null, non-empty URLs with `http` or `https` scheme. `launchExternalLink` returns `invalidScheme` for non-http URLs, `opened` on success, or `failed` if the platform launcher returns `false` or throws. The optional `launcher` parameter enables DI for tests.

### Link Confirm Sheet

`lib/features/chat/presentation/widgets/link_confirm_sheet.dart` — UI confirmation bottom-sheet for external links.

```dart
Future<void> showLinkConfirmSheet(
  BuildContext context, {
  required String href,
  Future<LinkLaunchResult> Function(String)? launcher,
})
```

Shows a dismissible bottom-sheet with `PremiumSheetShell`, `PremiumHandle`, `PremiumAvatar` (`Icons.open_in_new`), and `KeyboardHandlerDialog` (Enter confirms, Escape cancels). Displays the URL as selectable monospaced text with a copy button (`SnackbarUtils.showCopySnackBar`). On confirm, calls `launchExternalLink`; on failure, shows `SnackbarUtils.showErrorSnackBar` with `l10n.linkOpenFailed`. Non-http schemes are silently ignored.

### Usage Tracking API

#### `UsageCallback`

```dart
typedef UsageCallback = void Function(
  int input,
  int output,
  int cacheRead,
  int cacheWrite,
  int reasoning,
  bool cacheIncludedInInput,
);
```

Passed to `streamChatCompletion` via the `onUsage` parameter. Called when a turn completes with per-turn token breakdown.

#### `UsageCacheTokens` / `UsageRawData`

```dart
class UsageCacheTokens {
  final int read;
  final int write;
  const UsageCacheTokens({this.read = 0, this.write = 0});
}

class UsageRawData {
  final int inputTotal;
  final int outputTotal;
  final int cacheRead;
  final int cacheWrite;
  final int reasoning;
  final bool cacheIncludedInInput;
  const UsageRawData({
    this.inputTotal = 0,
    this.outputTotal = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.reasoning = 0,
    this.cacheIncludedInInput = false,
  });
}
```

#### `extractUsageRawData` / `resolveUsage`

```dart
UsageRawData extractUsageRawData(Object? rawUsage);
Map<String, dynamic> resolveUsage(
  LanguageModelV4Usage? usage,
  Map<String, dynamic>? capturedRawUsage,
);
```

`extractUsageRawData` maps provider-specific usage fields into a unified breakdown in one pass. Supported providers:

- OpenAI Chat Completions: `prompt_tokens_details.cached_tokens`.
- OpenAI Responses: `input_tokens_details.cached_tokens` / `cache_write_tokens`.
- DeepSeek: `prompt_cache_hit_tokens` (miss tokens are NOT cache writes — they are billed at full input price).
- Anthropic-compatible gateways: `cache_read_input_tokens` / `cache_creation_input_tokens`.

`resolveUsage` returns a map with keys: `inputTotal`, `outputTotal`, `cacheRead`, `cacheWrite`, `reasoning`, `cacheIncludedInInput`. The dead branch for unknown cache inclusion has been removed; `cacheIncludedInInput` is always resolved from raw usage or SDK data.

### PermissionService

Controls tool execution based on user-defined rules from `chatorai.json` and built-in defaults. Evaluates rules using wildcard patterns; last-match-wins; fallback=`ask` when no rule matches.

**Default rules** (defined in `PermissionRuleset.defaults()`, `lib/core/permission/ruleset.dart`):

| Tool                 | Default Action                      |
| -------------------- | ----------------------------------- |
| `read`               | `allow`                             |
| `glob`               | `allow`                             |
| `grep`               | `allow`                             |
| `webfetch`           | `allow`                             |
| `websearch`          | `allow`                             |
| `task`               | `deny`                             |
| `question`           | `deny`                             |
| `todowrite`          | `deny`                             |
| `skill`              | `allow`                             |
| `lsp`                | `allow`                             |
| `shell`              | `ask`                               |
| `edit`               | `ask`                               |
| `write`              | `ask`                               |
| `doom_loop`          | `ask`                               |
| `external_directory` | `ask`                               |
| `apply_patch`        | `ask` (fallback — no ruleset entry) |
| `format`             | `ask` (fallback — no ruleset entry) |
| `invalid`            | `ask` (fallback — no ruleset entry) |
| `plan_enter`         | `deny`                             |
| `plan_exit`          | `deny`                             |
| `json_schema`        | `ask` (fallback — no ruleset entry) |
| `document_extract_pdf` | `ask` (fallback — no ruleset entry) |
| `document_extract_docx` | `ask` (fallback — no ruleset entry) |
| `document_extract_xlsx` | `ask` (fallback — no ruleset entry) |

**Usage:**

```dart
await permissionService.ask(
  PermissionRequest(
    id: 'unique_id',
    toolName: 'shell',
    permission: 'shell', // matches PermissionRule.permission name
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

- All built-in tools registered in `built_in_tools.dart` via `registerBuiltInTools()` — 21 unconditional + up to 3 conditional (24 total possible).
- Conditional: `lsp` (when `LspService` is provided), `format` (when `FormatService` is provided), `skill` (when `SkillService` is provided).
- The `task` tool requires `chatAiService`, `toolRegistry`, and `currentSessionRunner` parameters.
- Permission defaults defined in `PermissionRuleset.defaults()` (`lib/core/permission/ruleset.dart`).
- Evaluation uses `evaluate()` from `lib/core/permission/evaluator.dart` — last-match-wins, fallback to `ask`.

### SessionRunner

Orchestrates session lifecycle with event sourcing. Accessed via the
`sessionRunnerProvider` Riverpod provider or through `session_providers.dart`.

**Key methods:**

```dart
// Start a new root session (synchronous — session is created immediately)
SessionRunnerSession startSession({
  required String agent, // 'general', 'explore', etc.
  String? modelRef, // model identifier from catalog
  String? title, // optional session title (auto-generated if omitted)
  String? parentSessionId, // for hierarchical sessions
  Duration toolCardGrace = const Duration(milliseconds: 1500),
})

// Start a re-initialization of an existing session
Future<SessionRunnerSession> startInitializedSession({
  required String agent,
  String? modelRef,
  String? title,
  String? parentSessionId,
  SessionID? sessionId, // existing session to continue
  String? messageId, // seed assistant message ID
  Duration toolCardGrace = const Duration(milliseconds: 1500),
})

// Run a delegated subagent task in a child session
Future<TaskChildResult> runTaskInChild({
  required SessionID parentSessionId,
  required String taskPrompt,
  required Future<void> Function(SessionRunnerSession child) streamFn,
  String? agent,
  String? modelRef,
  String? title,
  String? taskId,
  String? taskPartId,
  SessionRunnerHolder? holder,
  CancellationToken? abortSignal,
})
```

**`SessionRunnerSession` fields (selected public API):**

```dart
class SessionRunnerSession {
  final SessionRepository repository;
  final SessionID sessionId;
  final ToolRegistry? toolRegistry;
  final bool immediate;
  final String? _agent;      // private
  final String? _modelRef;   // private
  final String? _title;      // private
  final SessionID? _parentId; // private
  bool initialized;
  String? messageId;
}
```

`SessionRunnerSession` is an internal state object. Use the `SessionRepository`
and Riverpod providers (`sessionProviders`) for UI-level session operations.

**Usage via Riverpod providers:**

```dart
// In a widget or notifier:
final sessionRunner = ref.read(sessionRunnerProvider);
final session = sessionRunner.startSession(agent: 'general');
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
- `AssistantMessage` — assistant message with token tracking:
  - `tokensInput`, `tokensOutput`, `tokensReasoning`
  - `tokensCacheRead`, `tokensCacheWrite`
  - `tokensCacheIncludedInInput` — whether cache tokens are already included in `tokensInput` (avoids double-counting)
  - `contextLength` — model context limit at time of generation
  - `model` — model ID used for this turn
  - `agent` — agent name that produced this message
  - `isCompactionSummary` — whether this message is a compaction summary
- `SessionContextUsage` — aggregated context usage for the current chat:
  - `usedTokens`, `outputTokens`, `reasoningTokens`, `cacheReadTokens`, `cacheWriteTokens`, `toolTokens`, `toolCallsCount`
  - `contextLength`, `buffer`, `usable`
  - `sources` — list of `ContextInstructionSource` (agent prompt, user system prompt, instruction blocks)
  - `spentUsd` — session total cost in USD (null if no billable tokens)

**MessageParts** (serialized as JSON with `type` field):

| Part Type        | Description                                                    | Widget                 |
| ---------------- | -------------------------------------------------------------- | ---------------------- |
| `TextPart`       | Plain text content                                             | `TextPartWidget`       |
| `ReasoningPart`  | Model's thinking process (collapsible, with optional duration) | `ReasoningPartWidget`  |
| `ToolCallPart`   | Tool invocation (toolName, input)                              | `ToolCallPartWidget`   |
| `ToolResultPart` | Tool output (state, output, duration, error)                   | `ToolResultPartWidget` |
| `TaskPart`       | Delegated subagent task                                        | `TaskPartWidget`       |
| `QuestionPart`   | Multi-question flow awaiting user response                     | `QuestionPartWidget`   |
| `TodoPart`       | Todo list with items                                           | `TodoPartWidget`       |

**ReasoningPart fields** (defined in `lib/features/chat/data/models/chat/reasoning_part.dart`):

| Field         | Type        | Description                                                  |
| ------------- | ----------- | ------------------------------------------------------------ |
| `content`     | `String`    | The reasoning/thinking text                                  |
| `title`       | `String?`   | Optional display title                                       |
| `isStreaming` | `bool`      | Whether the part is still being streamed                     |
| `startedAt`   | `DateTime?` | When the reasoning started (used to compute `durationMs`)    |
| `durationMs`  | `int?`      | Computed duration in ms (set when streaming ends, persisted) |
| `isExpanded`  | `bool?`     | UI expand/collapse state                                     |

`durationMs` is computed when reasoning streaming ends (from `startedAt` to completion). It is persisted via `toJson()`/`fromJson()` and survives chat switches and app reloads. The `ReasoningPartWidget._displayDuration` getter prefers `widget.part.durationMs` over a locally computed `_thoughtDuration`.

**Note:** `ApplyPatchPart` and `SkillPart` are not implemented message part types. The `apply_patch` tool outputs via `ToolResultPartWidget` like any other tool.

---

## Tools

All tools implement the `Tool` interface from `ai_sdk_dart`. The `ToolRegistry` converts internal `ToolDef` implementations to SDK tools.

### Built-in Tools (24 total, 21 unconditional + 3 conditional)

**Always registered (21):**

| Tool                 | Description                            | Input Schema                                                            | Default Permission          |
| -------------------- | -------------------------------------- | ----------------------------------------------------------------------- | --------------------------- |
| `shell`              | Execute shell command                  | `{ "command": string, "timeoutMs": number }`                            | ask                         |
| `read`               | Read file contents                     | `{ "path": string, "offset": number, "limit": number }`                 | allow                       |
| `edit`               | Replace text in file                   | `{ "path": string, "oldString": string, "newString": string }`          | ask                         |
| `write`              | Create/overwrite file                  | `{ "content": string, "path": string }`                                 | ask                         |
| `glob`               | Find files by pattern                  | `{ "pattern": string, "path": string }`                                 | allow                       |
| `grep`               | Search file contents                   | `{ "pattern": string, "path": string, "filePattern": string }`          | allow                       |
| `webfetch`           | Fetch URL content                      | `{ "url": string, "format": "text" \| "markdown" \| "html" }`           | allow                       |
| `websearch`          | Search web via SearXNG                 | `{ "query": string, "engines": string[], "categories": string[] }`      | allow                       |
| `task`               | Spawn subagent via `SessionRunner`     | `{ "prompt": string, "context": object, "subagentType": string }`       | allow                       |
| `task_container`     | Run parallel subagent tasks, aggregate | `{ "tasks": [...], "strategy": "race" \| "all" }`                       | allow                       |
| `todowrite`          | Update todo list                       | `{ "todos": [{ "content": string, "status": "pending"/"completed" }] }` | allow                       |
| `question`           | Ask user question (with dedup)         | `{ "question": string, "options": string[], "multiple": bool }`         | allow                       |
| `apply_patch`        | Apply unified diff                     | `{ "patch": string, "dryRun": bool }`                                   | no default (fallback `ask`) |
| `invalid`            | Invalid tool placeholder               | `{}`                                                                    | no default (fallback `ask`) |
| `external_directory` | Directory operations (builtin)         | —                                                                       | ask                         |
| `plan_enter`         | Switch to plan agent mode              | —                                                                       | no default (fallback `ask`) |
| `plan_exit`          | Exit plan mode, switch to build agent  | —                                                                       | no default (fallback `ask`) |
| `json_schema`        | JSON schema validation                 | —                                                                       | no default (fallback `ask`) |
| `document_extract_pdf` | Extract text from PDF files           | `{ "path": string }`                                                    | no default (fallback `ask`) |
| `document_extract_docx` | Extract text from DOCX files         | `{ "path": string }`                                                    | no default (fallback `ask`) |
| `document_extract_xlsx` | Extract text from XLSX files         | `{ "path": string }`                                                    | no default (fallback `ask`) |

**Conditionally registered (up to 3):** All three checks are independent `if` statements — all three can be active simultaneously.

| Tool     | Condition                        | Default Permission          |
| -------- | -------------------------------- | --------------------------- |
| `lsp`    | When `LspService` is provided    | allow                       |
| `format` | When `FormatService` is provided | no default (fallback `ask`) |
| `skill`  | When `SkillService` is provided  | allow                       |

The actual registration in `registerBuiltInTools()` (see `lib/core/tools/built_in/built_in_tools.dart`) registers exactly **21 tools unconditionally**, plus up to 3 conditional tools (`lsp`, `format`, `skill`). Total: 21–24 built-in tools depending on available services. `skill` is **never** unconditionally registered — it requires `skillService != null`.

**Note on defaults:** `format`, `json_schema`, `apply_patch`, `invalid`, `plan_exit`, `document_extract_pdf`, `document_extract_docx`, `document_extract_xlsx` have no entry in `PermissionRuleset.defaults()`. When no rule matches the `evaluate()` function, the fallback action is `ask`.

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

| Event Type                     | Purpose                                                |
| ------------------------------ | ------------------------------------------------------ |
| `SessionCreated`               | New session with optional parent, title, agent, model. |
| `SessionArchived`              | Session archived (soft delete).                        |
| `SessionAgentSwitched`         | Agent changed mid-session.                             |
| `SessionModelSwitched`         | Model reference changed.                               |
| `MessageAdded`                 | User/assistant/system message persisted.               |
| `TextStarted/Delta/Ended`      | Assistant streaming text lifecycle.                    |
| `ReasoningStarted/Delta/Ended` | Reasoning/thinking stream lifecycle.                   |
| `ToolInputStarted/Delta/Ended` | Tool JSON input streaming (for progress UI).           |
| `ToolCalled`                   | Tool invoked with full input.                          |
| `ToolSuccess`                  | Tool completed (output, duration).                     |
| `ToolFailed`                   | Tool failed (error message).                           |
| `StepStarted/Ended/Failed`     | Turn lifecycle with token tracking.                    |
| `CompactionStarted/Ended`      | Context compaction with summary.                       |
| `ChildSessionCreated`          | Parent-child session hierarchy.                        |
| `TaskStarted/Completed`        | Delegated subagent task tracking.                      |

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
  version: 1,
  permission: {
    default: "ask",
    rules: [
      { tool: "read", action: "*", resource: "*", permission: "allow" },
      {
        tool: "shell",
        action: "execute",
        resource: "/home/**",
        permission: "deny",
      },
    ],
  },
  keybinding: {
    leader: "ctrl+x",
    timeout: 2000,
    bindings: { session_child_next: "ctrl+right" },
  },
  skills: {
    paths: [".chatorai/skills/"],
    urls: [],
  },
  compaction: { auto: true, prune: true },
  formatter: { formatters: {} },
  agent: {},
  mcp: {
    default_timeout: 30000,
    servers: {
      "my-server": {
        type: "local",
        command: "npx",
        args: ["-y", "my-mcp-server"],
      },
    },
  },
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

- `SessionRunner`: `startSession()`, `startInitializedSession()`, `runTaskInChild()` — orchestrates session lifecycle with event sourcing.
- `SessionRepository`: CRUD operations for sessions; event replay.
- `SessionTree`: Parent-child navigation in the session hierarchy.
- `EventStore`: `append()`, `read()`, `stream()` on the Drift event store.
- `McpClientService`: `initialize(config)`, `connect(serverName)`, `callTool(...)`, `listAllTools()`, `getToolDefs()`, `disconnect()`, `dispose()`.
- `mcp` CLI subcommand: `chatorai mcp` delegates to `runMcp()` in `lib/core/cli/mcp_cli.dart` for managing MCP servers (list/add/remove/enable/disable/tui).
- `ModelNotifier`: Manages model selection, favorites, usage tracking (`usageCounts`/`lastUsed`), available models, and the `recentModels` (top-6) getter.
- `PermissionRuleset`: `fromConfig(map)`, `defaults()`, merge via `PermissionEvaluator`.
- `ToolExecutor`: `execute(def, input, options)` — cache, doom-loop guard, permission check, truncation.
- `TruncationService`: Singleton, `output(content)` → truncated content + outputPath.
- `SessionState`: `Equatable` immutable model for session state reconstruction from events.
- `SessionMessage`: `Equatable` model with JSON serialization, `SessionIDConverter`, `MessageRole`.
- `SessionContextUsage`: Aggregated context usage (tokens, cache, spent USD, instruction sources) for the current chat.
- `UsageCacheTokens` / `UsageRawData`: Unified token breakdown from provider usage maps.
- `extractUsageRawData`: Maps provider-specific usage fields into unified breakdown.
- `resolveUsage`: Resolves usage map from SDK usage or raw usage capture.

---

For command-line usage and slash commands, see `docs/COMMANDS.md`.
For environment setup, see `docs/ENVIRONMENT.md`.
For architecture overview, see `ARCHITECTURE.md`.

## Diagrams

- [High-Level Data Flow](../diagrams/architecture-overview.md#high-level-data-flow)
- [Session Event Pipeline](../diagrams/architecture-overview.md#session-event-pipeline)
- [Tool Execution Lifecycle](../diagrams/architecture-overview.md#tool-execution-lifecycle)
- [MCP Connection Architecture](../diagrams/architecture-overview.md#mcp-connection-architecture)
- [Session Core ER & State Machine](../diagrams/sessions.md)
- [Tool Registry & Conditional Registration](../diagrams/tools.md)
