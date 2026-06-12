# API Reference

**Last updated:** 2026-06-12

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

| Provider | Type | Description |
|----------|------|-------------|
| `chatListProvider` | `NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>` | List of all chats with CRUD operations. |
| `chatScreenProvider` | `StateNotifierProvider<ChatScreenNotifier, ChatScreenState>` | UI state for chat screen (streaming, suggestions, sidebar, headings). |
| `streamingMessageProvider` | `StateNotifierProvider<StreamingMessageNotifier, StreamingMessageState>` | State for the currently streaming assistant message (parts accumulation). |
| `currentChatIdProvider` | `NotifierProvider<CurrentChatIdNotifier, String?>` | Currently active chat ID (router-level). |
| `currentChatProvider` | `Provider<Chat?>` | Computed chat by ID (derived from `currentChatIdProvider` + `chatListProvider`). |

### Model Providers

| Provider | Type | Description |
|----------|------|-------------|
| `modelProvider` | `StateNotifierProvider<ModelNotifier, ModelState>` | Model selection, favorites, available models from providers. |
| `themeProvider` | `StateNotifierProvider<ThemeNotifier, ThemeState>` | Theme, language, font size, wide screen mode. |

### Configuration Providers

| Provider | Type | Description |
|----------|------|-------------|
| `configProvider` | `Provider<ChatOrAIConfig>` | Validated `chatorai.json` configuration. |
| `permissionProvider` | `Provider<PermissionService>` | Permission service instance (singleton). |
| `providerSettingsProvider` | `StateNotifierProvider<ProviderSettingsNotifier, ProviderSettingsState>` | Multi-provider configuration (API keys, base URLs, selected models). |

### Core Services

| Provider | Type | Description |
|----------|------|-------------|
| `chatAiServiceProvider` | `Provider<ChatAiService>` | AI completion service with tool execution loop. |
| `chatRepositoryProvider` | `Provider<ChatRepository>` | Chat persistence repository. |
| `chatStorageServiceProvider` | `Provider<ChatStorageService>` | Local storage abstraction (SharedPreferences). |
| `toolRegistryProvider` | `FutureProvider<ToolRegistry>` | Registry of all available tools (12 built-in + dynamic skills). |
| `skillServiceProvider` | `FutureProvider<SkillService>` | Skill management service for dynamic capabilities. |

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

Controls tool execution based on user-defined rules from `chatorai.json`. Evaluates rules using wildcard patterns; last-match-wins; default=`ask`.

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
- Built-in tools registered in `built_in_tools.dart` (11 tools: bash, read, glob, grep, edit, write, webfetch, websearch, apply_patch, todo_write, task).
- `skill` tool registered separately via `skill_providers.dart`.
- `question` tool exists but is not currently registered.

### CompactionService

Automatically summarizes old messages when token budget is exceeded. Splits messages into head (old) + tail (recent), summarizes head via LLM, and prunes tool outputs older than 2 turns. Already implemented in `lib/core/context/compaction_service.dart`.

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

| Part Type | Description | Widget |
|-----------|-------------|--------|
| `TextPart` | Plain text content | `TextPartWidget` |
| `ReasoningPart` | Model's thinking process (collapsible) | `ReasoningPartWidget` |
| `ToolCallPart` | Tool invocation (toolName, input) | `ToolCallPartWidget` |
| `ToolResultPart` | Tool output (state, output, duration, error) | `ToolResultPartWidget` |
| `TaskPart` | Delegated subagent task | `TaskPartWidget` |
| `QuestionPart` | Multi-question flow awaiting user response | `QuestionPartWidget` |
| `TodoPart` | Todo list with items | `TodoPartWidget` |

**Note:** `ApplyPatchPart` and `SkillPart` are not implemented message part types. The `apply_patch` tool outputs via `ToolResultPartWidget` like any other tool.

---

## Tools

All tools implement the `Tool` interface from `ai_sdk_dart`. The `ToolRegistry` converts internal `ToolDef` implementations to SDK tools.

### Built-in Tools (12 total)

| Tool | Description | Input Schema | Default Permission |
|------|-------------|--------------|-------------------|
| `bash` | Execute shell command | `{ "command": string, "timeoutMs": number }` | ask |
| `read` | Read file contents | `{ "path": string, "offset": number, "limit": number }` | allow |
| `edit` | Replace text in file | `{ "path": string, "oldString": string, "newString": string }` | ask |
| `write` | Create/overwrite file | `{ "path": string, "content": string }` | ask |
| `glob` | Find files by pattern | `{ "pattern": string, "path": string }` | allow |
| `grep` | Search file contents | `{ "pattern": string, "path": string, "filePattern": string }` | allow |
| `webfetch` | Fetch URL content | `{ "url": string, "format": "text" \| "markdown" \| "html" }` | ask |
| `websearch` | Search web via SearXNG | `{ "query": string, "engines": string[], "categories": string[] }` | ask |
| `task` | Spawn subagent | `{ "prompt": string, "context": object, "subagentType": string }` | ask |
| `todowrite` | Update todo list | `{ "todos": [{ "content": string, "status": "pending"/"completed" }] }` | ask |
| `skill` | Load specialized skill | `{ "name": string, "params": object }` | ask |
| `apply_patch` | Apply unified diff | `{ "patch": string, "dryRun": bool }` | ask |

**Note:** The `question` tool exists but is not registered. All tool outputs render via `ToolResultPartWidget`; there is no separate `ApplyPatchPartWidget` or `SkillPartWidget`.

---

## Events

Streamed from `ChatAiService.streamChatCompletion()`:

| Event | Callback | Payload |
|-------|----------|---------|
| `Chunk` | `onChunk(String)` | Text delta appended to message. |
| `Reasoning` | `onReasoning(String)` | Thinking process delta. |
| `ToolStart` | `onToolStart(ToolStartEvent)` | Tool invoked (id, name, input). |
| `ToolEnd` | `onToolEnd(ToolEndEvent)` | Tool completed (result, duration). |
| `ToolError` | `onToolError(ToolError)` | Tool failed (error, isEOF). |
| `Completion` | `onCompletion(String)` | Final message ID / turn complete. |

---

## Configuration

### chatorai.json Schema

Location (searched in order):
1. `~/.config/chatorai/chatorai.json`
2. Project root `chatorai.json`

Validated against JSON Schema in `lib/core/config/chatorai_schema.dart`.

**Top-level sections:**

```json5
{
  "version": 1,
  "permission": {
    "default": "ask", // allow | deny | ask
    "rules": [
      { "tool": "read", "action": "*", "resource": "*", "permission": "allow" },
      { "tool": "bash", "action": "execute", "resource": "/home/**", "permission": "deny" }
    ]
  },
  "provider": {
    // Multi-provider registry configuration (implemented)
  },
  "keybinding": {
    // Reserved for future keybinds system (not yet implemented)
    "leader": "ctrl+x",
    "timeout": 2000,
    "bindings": { ... }
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
- `ModelNotifier`: Manages model selection, favorites, and available models (replaces `ModelRepository`).
- `TokenCounter`: `addContent(text)`, `clear()`, `totalTokens`.
- `OverflowDetector`: `isOverflow(totalTokens)`, `forModel(contextLength)`.
- `HeadingAnchorRegistry`: registers `GlobalKey` for markdown heading anchors.
- `CompactionService`: `compact(messages, aiService, model)` — summarizes old context when token budget exceeded.

---

For command-line usage and slash commands, see `docs/COMMANDS.md`.  
For environment setup, see `docs/ENVIRONMENT.md`.  
For architecture overview, see `ARCHITECTURE.md`.
