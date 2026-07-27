# ChatORAI Architecture

**Last updated:** 2026-07-08

## Project Overview

ChatORAI is a multi-platform AI chat application built with Flutter 3.44.0 and Riverpod 3.x. It supports any OpenAI-compatible API (OpenRouter, local models, custom endpoints) via `ai_sdk_dart` v1.1.0. Drift (SQLite) provides event-sourced session persistence; MCP (Model Context Protocol) enables integration with external tool servers.

Key characteristics:

- Feature-first directory structure
- MVVM pattern with Riverpod providers
- Layered architecture: Presentation → Domain → Data
- Event-sourced Session Core with Drift persistence
- Tool execution system with granular permissions and 16 built-in tools
- MCP (Model Context Protocol) support for external tool servers
- Internationalization with 6 languages (en, ru, uk, zh, ja, ar)

## Directory Layout

```
lib/
├── core/                    # Application core, cross-cutting concerns
│   ├── agents/              # Agent registry (static definitions for @-mention)
│   ├── background/          # Background task management
│   ├── config/              # Configuration management (chatorai.json, schema, loader)
│   ├── constants/           # App-wide constants, enums, themes
│   ├── context/             # Token counting, overflow detection, compaction
│   ├── error/               # Error classification and handling (sealed classes)
│   ├── format/              # Code formatting service (dart-mcp-server integration)
│   ├── i18n/                # Internationalization helpers
│   ├── keyboard/            # Centralized keyboard shortcuts (ShortcutHandler, AppShortcuts)
│   ├── llm/                 # LLM catalog system
│   │   ├── models/          # ProviderConfig, ModelConfig, AuthConfig, ModelVariant
│   │   ├── providers/       # Built-in provider definitions + catalog barrel
│   │   ├── catalog_providers.dart
│   │   └── provider_catalog_service.dart  # Centralized catalog with 24h cache
│   │   └── model_resolver.dart            # Resolves provider + model + auth headers
│   ├── lsp/                 # LSP service (dart-mcp-server_lsp integration)
│   ├── mcp/                 # MCP support (McpClientService, McpConfig, McpTypes)
│   ├── permission/          # Permission service and models (PermissionBridge)
│   ├── session/             # Event-sourced session core (Drift)
│   │   ├── schema.dart      # Drift table definitions
│   │   ├── database.dart    # Drift database class
│   │   ├── events.dart      # Sealed class hierarchy (30+ event types)
│   │   ├── event_store.dart # Append/read/stream operations
│   │   ├── projector.dart    # Pure event → SessionState functions
│   │   ├── session_state.dart # Freezed immutable state models
│   │   ├── session_repository.dart # CRUD + replay
│   │   ├── session_runner.dart  # Session lifecycle orchestrator
│   │   ├── session_tree.dart    # Parent-child navigation
│   │   ├── session_stack.dart   # Hierarchical session navigation
│   │   ├── session_id.dart     # Branded SessionID type
│   │   └── session_db_provider.dart # Riverpod provider for database
│   ├── skills/              # SkillService for dynamic capability loading
│   │   ├── directory_source.dart
│   │   ├── url_source.dart
│   │   ├── skill_cache.dart
│   │   ├── skill_discovery.dart
│   │   ├── skill_service.dart
│   │   └── ...
│   └── tools/               # Built-in tool implementations (16 tools + 3 conditional)
│       ├── built_in/        # Individual tool implementations
│       ├── permission_bridge.dart        # Integrates tool permission requests
│       ├── secure_file_service.dart      # Filesystem boundary enforcement
│       ├── truncation_service.dart      # Context-overflow prevention (truncates + persists large outputs to the managed data dir)
│       ├── tool_execution.dart  # Execution context with doom-loop guard
│       │   ├── file_edit_guard.dart     # File edit permission checks
│       │   ├── filesystem_boundary.dart # Path sandboxing
│       │   utils/               # Shared utilities (logger, formatters, secure storage, xdg_paths)
├── features/                # Feature-based modules (primary organization)
│   ├── agents/              # Subagent system and registry
│   ├── chat/                # Main chat feature (domain, data, presentation)
│   │   ├── domain/
│   │   │   └── services/    # ChatAiService, SessionRunner integration
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── chat/    # Message and parts hierarchy
│   │   │   ├── repositories/
│   │   │   └── providers/   # Riverpod providers (session, streaming, screen)
│   │   └── presentation/
│   │       ├── screens/     # ChatScreen (split into parts)
│   │       ├── widgets/     # ChatMessages, ChatInput, parts/
│   │       └── chat_input/  # Subdirectory for input components (agent_mention_popup)
│   ├── models/              # Model selection and provider management
│   │   ├── providers/       # ModelProvider
│   │   ├── screens/         # ModelsScreen
│   │   └── widgets/         # ProviderIcon, ModelCard, ModelDetailsDialog, etc.
│   ├── settings/            # App settings, theme, language, API key
│   │   ├── providers/       # Model settings provider
│   │   ├── screens/         # SettingsScreen, ProviderSettingsScreen
│   │   └── widgets/         # AddProviderDialog, ModelSelectionDialog, etc.
│   └── skills/              # Skill-based agent capabilities and SkillService
├── generated/               # Auto-generated localization (app_localizations.dart)
└── l10n/                    # ARB files for translation (6 languages)
```

## Architectural Patterns

### MVVM with Riverpod 3.x

- **Providers**: All state is exposed via Riverpod `Notifier` subclasses (`NotifierProvider`, `AsyncNotifierProvider`) and `Provider`/`FutureProvider` for derived/async values. `StateNotifier`/`ChangeNotifier` are not used.
- **ViewModels**: Notifier classes manage business logic and state transitions.
- **Views**: Stateless widgets that `ref.watch` providers for reactive updates.

### Layered Separation

Each feature follows a multi-layer structure:

- **Domain Layer**: Pure business logic, entities (ChatMessage, MessagePart), repository interfaces, services (ChatAiService). No Flutter dependencies.
- **Data Layer**: Repository implementations, data sources (local: SharedPreferences; remote: API via Dio), DTOs, model mapping.
- **Presentation Layer**: Flutter widgets, Riverpod providers for UI state, view models.

### Session Runner Pipeline

`SessionRunner` orchestrates AI completions with tool execution within an event-sourced session:

1. `startSession()` or `startInitializedSession()` creates a new session (with optional parent for hierarchy).
2. `runTaskInChild()` spawns a child session for delegated subagent work.
3. Within a session turn:
   - `ModelResolver` resolves provider + model configuration and auth headers.
   - `ChatAiService.streamChatCompletion()` sends messages to the provider API.
   - Stream of `StreamTextEvent` chunks (text, reasoning, tool events).
   - `SessionRunnerSession` tracks explicit part IDs for text, reasoning, and tool segments.
   - `sessionPartsProvider` provides reactive streaming of both parent and child sessions.
   - Tool invocation lifecycle: `onToolStart` → `tool.execute()` → `onToolEnd`/`onToolError`.
   - Each event is persisted to the `EventStore` (append-only).
   - The `Projector` replays events to reconstruct `SessionState` on demand.
   - Complex assistant content (`AssistantTask`, `AssistantQuestion`, `AssistantTodo`) is projected as typed parts.
4. Max steps: 5 per turn, with automatic compaction on overflow.
5. Error handling: retries with exponential backoff via `ChatRetryService`, `Retry-After` support, sealed `ClassifiedError` hierarchy.

### Chat Retry & Resilience

`ChatRetryService` wraps child completions and API calls with unbounded retry logic:

- Infinite retries for retryable errors (network failures, rate limits).
- Exponential backoff with jitter (base 2s, cap 30s).
- Respects `Retry-After` headers from providers.
- Non-retryable errors (auth, content policy) fail immediately.

### Keyboard Shortcuts

`ShortcutHandler` and `AppShortcuts` provide centralized keyboard shortcut management:

- Shortcuts are currently hardcoded; `chatorai.json` `keybinding` section is parsed but not applied at runtime.
- Future work: wire config keybindings into the shortcut system.

### Permission System

- Configured via `chatorai.json` (section `permission`).
- Default ruleset: `read`, `glob`, `grep` → `allow`; others → `ask`.
- Evaluator: last-match-wins, default=`ask`.
- UI Modal: Once / Always allow / Reject. "Always" promotes to runtime ruleset.
- Integration: `tool.preExecute()` → `PermissionService.ask()` → `tool.execute()`.
- **Implementation location:** `lib/core/permission/permission_service.dart`

### Configuration Management

- **Development**: `.env` (gitignored) for API keys and dev settings.
- **Runtime**: Users enter API key in app settings → stored in `SharedPreferences`.
- **chatorai.json**: User-editable JSON with `$schema` URL for IDE autocomplete. Validated against `lib/core/config/chatorai_schema.dart`.
- Sections: `permission`, `keybinding` (parsed but not applied at runtime), `skills`, `compaction`, `formatter`, `agent` (per-agent overrides), `mcp` (MCP server definitions).

### Internationalization

- ARB files in `lib/l10n/` for 6 languages.
- RTL support for Arabic.
- After editing any ARB: `flutter gen-l10n`.
- Generated output: `lib/generated/app_localizations.dart` (do not edit manually).

### Platform Specifics

- **Linux**: Requires `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`.
- **Windows**: Visual C++ workload + Windows 10/11 SDK required for builds; CMake errors if missing.
- **iOS**: Requires macOS; cannot build on Linux.

## Provider Catalog System

### Caching Strategy

`ProviderCatalogService.discoverModels()` implements a time-based cache:

1. On first call (or after cache expiry), fetches models from the provider's `/models` endpoint via `Dio`.
2. Persists the discovery timestamp in SharedPreferences under key `catalog_discovered_at_{providerId}`.
3. Subsequent calls return cached models if the timestamp is younger than `cacheDuration` (default: 24 hours).
4. Pass `forceRefresh: true` to bypass the cache and re-fetch.
5. `cacheDuration` is a constructor parameter on `ProviderCatalogService`, overridable for testing.

Cache keys (SharedPreferences):

- `catalog_provider_enabled_{id}` — whether the provider is enabled
- `catalog_provider_base_url_{id}` — custom base URL override
- `catalog_provider_api_key_{id}` — API key (also mirrored in SecureStorage)
- `catalog_selected_{id}` — set of selected model IDs
- `catalog_provider_models_{id}` — cached model list
- `catalog_discovered_at_{id}` — last discovery timestamp (ms since epoch)

### Adding a New Built-in Provider

1. Create a file in `lib/core/llm/providers/` (e.g. `my_provider.dart`) exporting a top-level function that returns a `ProviderConfig`.
2. Import the new file in `lib/core/llm/providers/built_in_providers.dart` and add the function call to the `builtInProviders()` list.
3. Add an SVG icon to `assets/provider/` and register the mapping in `_iconMap` inside `lib/features/models/widgets/provider_icon.dart`.
4. Verify `assets/provider/` is listed in `pubspec.yaml` under `flutter: assets:`.

### ProviderIcon Widget

`lib/features/models/widgets/provider_icon.dart`:

- Static `_iconMap` maps provider ID strings to SVG asset paths.
- `ColorFiltered(BlendMode.srcIn)` applies the current theme color (white in dark mode, black in light mode).
- Falls back to `Icons.smart_toy_outlined` for unknown provider IDs.
- Usage: `ProviderIcon(providerId: 'openrouter', size: 28)`.

### Add Provider Flow

```
User taps "Add Provider"
  → AddProviderDialog
    → Dropdown with all built-in providers (icons via ProviderIcon) + "Custom" entry
    → On built-in selection: auto-fills baseUrl from ProviderConfig
    → On Custom selection: shows name field, generates ID (fallback: custom_<timestamp> for non-Latin names)
    → User enters API key, optionally overrides baseUrl
    → Save → onSave callback
      → For built-in: catalog.setApiKey(id, key), catalog.setProviderEnabled(id, true)
      → For custom: catalog.addCustomProvider(ProviderConfig.basic(...))
  → ModelSelectionDialog
    → Receives ProviderCatalogService instance
    → Calls catalog.discoverModels(providerId) — uses cache if fresh
    → Renders List<ModelConfig> with checkboxes
    → Save → catalog.setSelectedModelIds(providerId, ids)
      → Also calls catalog.updateProviderModels(providerId, models) [awaited]
```

### Custom Provider Flow

`addCustomProvider(ProviderConfig provider)`:

1. Removes any existing provider with the same ID.
2. Appends the new provider to the internal list.
3. Persists the custom providers list to SharedPreferences.
4. The custom provider then participates in `getAllProviders()`, `getModel()`, and `discoverModels()` like any built-in provider.

## Data Flow

```
User types message
  ↓
ChatInput widget → onSendMessage callback
  ↓
chatScreenNotifier.sendMessage()
  ↓
ChatAiService.streamChatCompletion(...)
  ↓
Message chunks streamed:
  - TextPart (content)
  - ReasoningPart (thinking process)
  - ToolCallPart / ToolResultPart (tool execution)
  - TaskPart / QuestionPart / TodoPart (special workflows)
  ↓
ChatStorageService.addMessageToChat() persists messages
  ↓
Providers update state → UI rebuilds (ChatMessages, ChatMessageBubble)
```

### Streaming & Auto-scroll

- Streaming updates throttled to 250ms or word boundaries (whichever comes first).
- Auto-scroll during streaming is enabled/disabled based on user scroll position:
  - Near bottom (≤150px) → auto-scroll stays ON.
  - Scrolled up (>150px) → auto-scroll OFF until user returns near bottom.
- After sending a message: smooth force scroll (300ms animation).
- Assistant bubble wrapped in `AnimatedSize(150ms)` synchronized with streaming scroll to prevent text overflow.

## Component Boundaries

### Chat Feature Module

```
lib/features/chat/
├── domain/
│   ├── services/
│   │   └── chat_ai_service.dart    # AI completion with tool loop (legacy; SessionRunner preferred)
├── data/
│   ├── models/
│   │   └── chat/                  # Message and parts hierarchy
│   │       ├── chat_message.dart  # UserMessage, AssistantMessage, SystemMessage, ErrorMessage
│   │       ├── message_part.dart  # Abstract part base
│   │       ├── text_part.dart
│   │       ├── reasoning_part.dart
│   │       ├── tool_call_part.dart
│   │       ├── tool_result_part.dart
│   │       ├── task_part.dart
│   │       ├── question_part.dart
│   │       ├── todo_part.dart
│   │       ├── chat_message_export.dart
│   │       └── message_converter.dart
│   ├── repositories/
│   │   └── chat_repository_impl.dart
│   └── providers/
│       ├── session_providers.dart    # Session-based providers (new architecture)
│       ├── session_parts_provider.dart # Unified reactive session streaming
│       ├── chat_screen_notifier.dart
│       ├── chat_input_provider.dart
│       └── sidebar_provider.dart
└── presentation/
    ├── screens/
    │   ├── chat_screen.dart
    │   ├── chat_screen_ai.dart
    │   ├── chat_screen_build.dart
    │   ├── chat_screen_edits.dart
    │   ├── chat_screen_management.dart
    │   ├── chat_screen_messaging.dart
    │   ├── chat_screen_navigator.dart
    │   ├── chat_screen_part_placeholder.dart
    │   ├── chat_screen_scroll.dart
    │   ├── chat_screen_streaming.dart
    │   └── child_session_screen.dart
    ├── widgets/
    │   ├── chat_messages.dart
    │   ├── chat_message_bubble.dart
    │   ├── chat_input.dart          # @-mention triggers implemented; # and / planned
    │   ├── chat_input/             # Input sub-components
    │   │   ├── agent_mention_handler.dart
    │   │   ├── agent_mention_popup.dart
    │   │   ├── attachment_input_handler.dart
    │   │   ├── command_popup.dart
    │   │   ├── file_helpers.dart
    │   │   ├── input_layout_builder.dart
    │   │   ├── input_widget_builders.dart
    │   │   ├── message_data.dart
    │   │   ├── popup_controller.dart
    │   │   ├── send_message_handler.dart
    │   │   ├── skills_popup.dart
    │   │   ├── slash_command_handler.dart
    │   │   └── speech_input_handler.dart
    │   ├── parts/                  # One widget per MessagePart type
    │   │   ├── text_part_widget.dart
    │   │   ├── reasoning_part_widget.dart
    │   │   ├── tool_call_part_widget.dart
    │   │   ├── tool_result_part_widget.dart
    │   │   ├── task_part_widget.dart
    │   │   ├── question_part_widget.dart
    │   │   └── todo_part_widget.dart
    │   ├── permission_dialog.dart
    │   ├── permission_overlay.dart
    │   ├── sidebar.dart
    │   ├── sidebar_wrapper.dart
    │   ├── markdown_navigator_sidebar.dart
    │   ├── model_settings_header.dart
    │   ├── chat_app_bar.dart
    │   └── ...
    └── view_models/                # Not used; logic in providers
```

**Note:** Message models are in `data/models/chat/`. The `apply_patch_part_widget.dart` does not exist; `ApplyPatchPart` is not a recognized message part type. Only `@` triggers are currently implemented in `chat_input.dart`; `#` (file references) and `/` (slash commands) are planned. The `QuestionPart` widget is rendered inline in the chat stream for interactive user prompts.

### Tools Module (`lib/core/tools/`)

```
lib/core/tools/
├── built_in/                      # 16+ built-in tool implementations
│   ├── shell.dart                 # Shell command execution
│   ├── read.dart                 # File reading
│   ├── write.dart                # File creation/overwrite
│   ├── edit.dart                 # In-file text replacement
│   ├── glob.dart                 # File pattern matching
│   ├── grep.dart                 # Content search
│   ├── webfetch.dart             # URL content fetching
│   ├── websearch.dart            # Web search via SearXNG
│   ├── apply_patch.dart          # Unified diff application
│   ├── task.dart                 # Subagent delegation (needs SessionRunner)
│   ├── question.dart             # Interactive question with cooldown dedup
│   ├── todowrite.dart           # Todo list management
│   ├── skill.dart                # Skill loading via SkillService
│   ├── lsp.dart                  # LSP hover/info via dart-mcp-server_lsp
│   ├── format.dart               # Code formatting via FormatService
│   ├── invalid.dart              # Invalid tool placeholder (for unknown tool IDs)
│   ├── external_directory.dart   # External directory reference
│   ├── json_schema.dart          # JSON schema validation
│   ├── plan.dart                 # Plan exit tool
│   └── built_in_tools.dart       # Registration barrel (registers 16+ tools)
├── permission_bridge.dart        # Integrates tool permission requests with PermissionService
├── secure_file_service.dart      # Filesystem boundary checks and external directory access
├── truncation_service.dart       # Prevents context overflow; truncates + saves large outputs to the managed data dir
├── tool_permission.dart          # Tool permission metadata and helpers
├── tool.dart                     # Tool interface
├── tool_definition.dart          # ToolDef model
├── tool_error.dart               # Tool error types (sealed ToolError)
├── tool_execution.dart           # Execution context with doom-loop guard
├── tool_output_persistence.dart  # Persistent tool output storage
├── tool_output_metadata.dart     # Output metadata tracking
├── tool_registry.dart            # Singleton registry, toSDKTools()
├── tool_registry_provider.dart   # Riverpod provider
├── tool_title.dart               # Tool title formatting
├── file_edit_guard.dart          # File edit permission boundary checks
├── filesystem_boundary.dart      # Path sandboxing enforcement
└── json_schema_validator.dart    # JSON schema validation logic
```

**Registration details:** `registerBuiltInTools()` accepts optional `chatAiService`, `toolRegistry`, `skillService`, `lspService`, `formatService`, `formatterConfig`, and `currentSessionRunner` parameters. The `question` tool is now registered. The `lsp` and `format` tools are conditionally registered when their services are provided.

### MCP (Model Context Protocol) Module

```
lib/core/mcp/
├── mcp_config.dart           — McpConfig, McpServerConfig, McpOAuthConfig models
├── mcp_types.dart            — McpToolInfo, McpCallResult, McpContentPart, etc.
└── mcp_client_service.dart   — McpClientService (singleton)
```

`McpClientService` manages connections to external MCP servers:

- Local servers via `StdioClientTransport`
- Remote servers via `StreamableHttpClientTransport`
- Tool discovery (`listTools`, `listAllTools`)
- Tool invocation (`callTool`)
- Config from `chatorai.json` `mcp` section

### LSP Integration

```
lib/core/lsp/
├── lsp_service.dart    — LspService: 15-language server table, auto-install dispatch, lazy file-driven client lifecycle
├── lsp_client.dart     — LspClient: JSON-RPC adapter, didOpen/didChange/didClose lifecycle, stream controller
├── lsp_types.dart      — LSP types (LspDiagnostic, LspRange, LspPosition, LspPublishDiagnosticsParams, ...)
├── lsp_methods.dart    — LspMethod constants + state enums
└── lsp_provider.dart   — Riverpod providers (lspServiceProvider, lspClientProvider)
```

`LspService` manages a cache of `LspClient` instances keyed by `(rootUri, serverId)`.

- **Built-in table**: 15 `LspServerDefinition` entries in `_builtInServers` (dart, typescript, python, java, kotlin, go, rust, csharp, yaml, shell, clangd, lua, markdown, swift, zig). Each entry specifies `command`, `args`, `extensions`, optional `autoInstall` hint, and optional `env`.
- **Auto-install**: When a command is missing on PATH, `LspService.clientForFile()` checks the built-in `AutoInstallHint` and invokes the platform package manager (`npm`, `cargo`, `brew`, `pip`, `go`) once per server ID. Path checks are bounded by a 5-second `Process.run` timeout.
- **Config models**: `LspConfig` (top-level `lsp` section) and `LspServerEntryConfig` (per-server overrides) in `lib/core/config/models/chatorai_config.dart`. `LspConfig.fromJson` accepts both `lsp: true/false` and `lsp: { servers: { ... } }`.
- **Provider wiring**: `lspServiceProvider` (FutureProvider) loads user overrides via `service.loadUserServers(config.lsp!)` at startup and calls `service.shutdownAll()` on dispose.
- **Concurrency**: `_activeCreation` map guards against duplicate client creation per cache key.
- **Diagnostics lifecycle**: `diagnostics()` opens a file, subscribes to the diagnostics stream, and sends `textDocument/didClose` in the `finally` block. `diagnosticsForFile()` follows the same pattern with a configurable 3-second timeout. `_openedFiles` is cleared in `shutdownAll()`.
- **Dead code removed**: `_legacyFallback` path removed.

The `lsp` tool is registered conditionally when `LspService` is provided.

### Models & Settings Feature Modules

```
lib/features/models/
├── providers/
│   └── model_provider.dart    # Riverpod Notifier for model state
├── screens/
│   └── models_screen.dart     # Model selection screen (incl. Recent strip)
└── widgets/
    ├── provider_icon.dart     # SVG icon widget with theme-aware ColorFiltered
    ├── model_card_widget.dart
    ├── model_details_dialog_widget.dart
    ├── model_features_widget.dart
    └── models_empty_state_widget.dart

lib/features/settings/
├── providers/
│   └── model_settings_provider.dart
├── screens/
│   ├── settings_screen.dart
│   ├── provider_settings_screen.dart
│   ├── provider_settings_actions.dart
│   └── provider_settings_dialogs.dart
└── widgets/
    ├── add_provider_dialog.dart      # Provider selection + custom provider flow
    ├── model_selection_dialog.dart   # Model discovery via catalog (no direct Dio)
    ├── provider_card.dart
    └── ... (other settings widgets)
```

`ModelState` (`model_provider.dart`) tracks `favoriteModelIds`, `usageCounts` (per-model `int`), and `lastUsed` (per-model timestamp), all persisted in `SharedPreferences` alongside the selected model. `setSelectedModel` increments the usage count and refreshes `lastUsed`. The `recentModels` getter returns the top-6 models merged by usage count (desc) then last-used timestamp (desc), limited to currently available models. `ModelsScreen` renders these in a horizontal "stories"-style `_RecentModelsSection` above the grouped provider list, with a localized "Recent" header (6 languages).

## State Management

- **Riverpod 3.x** exclusively.
- Use `Notifier` subclasses (`StateNotifier` deprecated).
- Avoid creating new `StatefulWidget`; prefer `StateProvider` + `Consumer`.
- In tests: use `ProviderContainer` directly (see `test/test_chat_input_provider.dart`).

## Reliability & Security

- **Retry**: Unbounded exponential backoff with jitter, respects `Retry-After` headers.
- **Cancellation**: `CancellationToken` via `ChatAiService.cancelAllRequests()` on emergency stop.
- **Sanitization**: No secrets in logs; user-facing errors are truncated, no stack traces.
- **Storage**: `.env` dev-only; runtime API key in `SharedPreferences`.
- **TLS**: Enforced for all external requests via Dio.
- **Rate Limiting**: Implemented at provider level (OpenRouter rate limits respected via backoff).

## Development Commands

```bash
flutter pub get              # fetch dependencies
flutter gen-l10n             # ONLY after editing lib/l10n/*.arb
flutter analyze             # lint (tests excluded via analysis_options.yaml)
dart analyze <file1> <file2>  # targeted lint on specific files
flutter test                # unit + widget tests
dart test test/core/ai/catalog/unit/provider_catalog_service_test.dart  # catalog tests (43 cases)
LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux  # Linux software rendering
```

## Testing Strategy

- Unit tests: Business logic, services, providers. Key suite: `test/core/ai/catalog/unit/provider_catalog_service_test.dart` (43 tests covering cache, persistence, custom providers, edge cases).
- Widget tests: UI components, auto-scroll behavior, rendering.
- Integration tests: Currently problematic; run via standalone scripts (e.g., `integration_test/api_test.dart`).
- `flutter analyze` clean required; tests do not block lint.

## Future Considerations

- **Keybinds System**: GUI hotkeys for desktop (planning phase — `keybinding` section reserved in config schema).
- **Emergency Stop**: Double-press Escape to halt all active processes, preserving session state.
- **Dynamic Agent Discovery**: Currently static (`AgentRegistry`); dynamic skill-based discovery via MCP servers is a future goal.
- **File Export/Import**: Session export to JSON/Markdown for sharing and archival.
- **Crash Recovery**: Full event replay from Session Core already implemented; UI indicator for session restoring is a remaining UX polish.
- **Advanced MCP**: OAuth flow for remote MCP servers, SSE transport for streaming tool results.

**Note:** The Compaction Service, Session Hierarchy, and MCP/LSP integration are implemented. The Session Core uses Drift-based event sourcing with full replay capability.

### Provider Options

`ProviderConfig.buildProviderOptions()` and `ProviderConfig.buildProviderHeaders()`:

- `buildProviderOptions()` merges provider `defaultBody`, model `providerOptions` metadata, and variant `body` in order (later wins). Used for provider-specific parameters like Anthropic `thinkingConfig`, OpenAI `reasoningEffort`, or Bedrock `promptCacheKey`.
- `buildProviderHeaders()` merges provider `defaultHeaders`, variant `headers`, and call-time `overrideHeaders` in order (later wins).

These are used by `ModelResolver.getBodyForModel()` and `ModelResolver.getHeadersForModel()`.

### Bedrock Provider

Amazon Bedrock (`sdk: 'bedrock'`) requires `AuthType.aws` with `awsAccessKeyId`, `awsSecretAccessKey`, and `awsRegion`. Native AWS SigV4 signing is not yet implemented; the resolver throws a clear error until Bedrock-native SDK integration is added.

---

For user-facing documentation, see `README.md`. For environment setup, see `docs/ENVIRONMENT.md`. For API reference, see `docs/API.md`. For changelog and release notes, see `CHANGELOG.md`. For platform path conventions, see `docs/xdg-paths.md`.
