# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0]

First public release.

### Added

- One-command prebuilt install for Linux (`install_chatorai.sh`), Windows (`install_chatorai.ps1`/`.bat`), and macOS (`.dmg`). No Flutter SDK required for end users.
- `chatorai upgrade [target]` command for in-app updates (downloads latest release from GitHub and installs to `/usr/local/lib/chatorai`).

- **Session Parts Provider**: New `sessionPartsProvider` for reactive streaming of both parent and child sessions, replacing the legacy `streamingMessageProvider` with a granular part-based approach.

### Changed

- **Bash tool security policy**: Changed default `bash` permission from `allow` to `ask` in `PermissionRuleset.defaults()`. Removed `DangerousCharacterPolicy` from `lib/core/tools/built_in/bash.dart` that was overly aggressive in flagging safe shell metacharacters (`|`, `>`, `<`, `&`) as `highRisk`. Safe commands (`find`, `echo hello | cat`, etc.) now run without prompts; medium/high-risk commands (`echo foo; echo bar`, `rm -rf /`, blocked executables) trigger permission dialogs. Nothing is harshly denied — only `ask` or `allow`.
- **Sensitive env file protection**: Added `*.env` and `*.env.*` to default `read` permission rules as `ask`. Added `ArgumentPatternPolicy` in bash tool to detect `cat/less/more/head/tail/vi/vim/nvim/nano .env` commands as `highRisk` review. `.env.example` remains `allow`.
- **Explicit Part IDs**: `SessionRunnerSession` now tracks explicit part IDs for text, reasoning, and tool-related content segments.
- **QuestionOption Model**: New `QuestionOption` model supports richer interactive questions with `multiple` selection support.
- **ShortcutHandler & AppShortcuts**: Centralized keyboard shortcut management widget.
- **SecureFileService**: New service for filesystem boundary enforcement and external directory access authorization.
- **PermissionBridge**: New bridge integrating tool-specific permission requests with the existing `PermissionService`.
- **ToolOutputBoundingService**: Prevents context overflow by truncating large tool outputs and saving them to disk.
- **ChatRetryService**: Infinite retries for retryable errors with exponential backoff and `Retry-After` header support.
- **Enhanced SessionEvent Schema**: Support for task-specific parts and improved metadata persistence.
- **AssistantQuestion Multiple Selection**: `AssistantQuestion` now supports `multiple` boolean for multi-select questions.
- **ChatScreen Refactor**: Split into focused files (`chat_screen_ai.dart`, `chat_screen_edits.dart`, `chat_screen_build.dart`, `chat_screen_messaging.dart`, `chat_screen_management.dart`, `chat_screen_navigator.dart`, `chat_screen_part_placeholder.dart`).
- **Widget Parts Split**: Tool body and display widgets separated into individual files:
  `_bash_body_widget.dart`, `_read_body_widget.dart`, `_grep_body_widget.dart`,
  `_write_body_widget.dart`, `_edit_body_widget.dart`, `_lsp_body_widget.dart`,
  `_patch_body_widget.dart`, `_generic_body_widget.dart`, `_diff_line_widget.dart`,
  `_webfetch_body_widget.dart`, `_tool_icon.dart`, `_tool_title.dart`.
  49 new tests added.
- **Widget Refactoring Phase 2**: Extracted shared formatting utilities to `lib/shared/utils/format_utils.dart` with `formatTokenCount`, `tokenDisplay`, `formatDurationMs`, `formatDuration`, and `bashPreview` to eliminate code duplication across `action_row.dart`, `task_part_widget.dart`, and `reasoning_part_widget.dart`.
- **UserMessageEdit Widget**: Extracted user message editing interface from `ChatMessageBubble` into a dedicated `lib/features/chat/presentation/widgets/parts/user_message_edit.dart` file, reducing `ChatMessageBubble` responsibility to message dispatching only.
- **Unified ContinuationSuggestions**: Removed duplicate `_ContinuationSuggestions` from `assistant_bubble.dart`; now uses the shared `ContinuationSuggestions` from `action_menu_button.dart`.
- **Renamed tool body widgets** (removed underscore prefix for consistency):
  - `_bash_body_widget.dart` → `bash_body.dart`
  - `_read_body_widget.dart` → `read_body.dart`
  - `_grep_body_widget.dart` → `grep_body.dart`
  - `_write_body_widget.dart` → `write_body.dart`
  - `_edit_body_widget.dart` → `edit_body.dart`
  - `_lsp_body_widget.dart` → `lsp_body.dart`
  - `_patch_body_widget.dart` → `patch_body.dart`
  - `_webfetch_body_widget.dart` → `webfetch_body.dart`
  - `_generic_body_widget.dart` → `generic_body.dart`
  - `_diff_line_widget.dart` → `diff_line.dart`
  - `_tool_icon.dart` → `tool_icon.dart`
  - `_tool_title.dart` → `tool_title.dart`
- **Eliminated duplicate `bashPreview`**: Removed duplicate implementation from `tool_result_part_widget.dart`; now imports and uses the shared version from `format_utils.dart`.
- **Centralized duration formatting**: `task_part_widget.dart` and `reasoning_part_widget.dart` now use shared `formatDurationMs(int?)` and `formatDuration(Duration)` from `format_utils.dart`.
- **Empty directory cleanup**: Confirmed empty `lib/features/chat/presentation/widgets/chat/` directory already removed.

### Fixed

- **Linter warnings**: Resolved unused imports and dangling library doc comments introduced during refactoring. `flutter analyze` reports zero issues.
- **Unused imports cleaned up**: Removed stale imports from `chat_message_bubble.dart`, `user_message_edit.dart`, and `format_utils.dart`.
- **Bash tool security policy**: Changed command_shield policies in `lib/core/tools/built_in/bash.dart` from immediate `deny` to `review` (ask-permission flow). `DangerousCharacterPolicy` now returns `review` at `highRisk` level; `ArgumentPatternPolicy` for `chmod` and redirect patterns now return `review`; `ExecutableBlockListPolicy` uses `onMatch: CommandDecision.review`; replaced `RiskThresholdPolicy` with custom `_ReviewOnlyPolicy` that never denies and always asks permission for `mediumRisk` and above. Removed duplicate blocked-executable deny check. Verified with `dart analyze` (clean) and `flutter test test/integration/bash_integration_test.dart` (15/15 passed). Goal: commands such as `curl`, `rm -rf`, and `npm` now trigger a permission dialog instead of being immediately blocked.

### Documentation

- **docs/API.md**: Fixed tool permission table (7 tools had wrong defaults: `webfetch`, `websearch`, `task`, `todowrite`, `question`, `skill`, `lsp` were `ask` in docs but `allow` in code). Corrected total tool count from 16 to 19 (16 unconditional + 3 conditional). Added `ReasoningPart` field documentation with `durationMs` persistence details. Fixed `McpClientService` line (was truncated). Removed duplicate Internal APIs entries. Updated top-level schema sections to match actual `chatorai_schema.dart` (added `skills`, `compaction`, `formatter`; removed stale `provider`).
- **docs/COMMANDS.md**: Updated tool permission table to match corrected data. Removed redundant input schema column (now references API.md). Removed incorrect "5-min cooldown" mention for `question` tool (dedup mechanism differs).
- **docs/ENVIRONMENT.md**: Updated example JSON — removed stale `provider` block, added `skills`, `compaction`, `formatter` sections. Fixed MCP server type enum (`stdio`/`http` → `local`/`remote`). Added `default_timeout` to MCP section.
- **docs/configuration.md**: Added missing `skills`, `compaction`, `formatter` config sections. Completed default rules table (added 9 missing entries: `task`, `question`, `todowrite`, `skill`, `lsp`, `external_directory`; clarified `apply_patch`/`format`/`invalid` fallback behavior). Updated MCP server type enum. Fixed `provider` section (removed "Currently not used"). Fixed `keybinding` status: no `KeybindManager` class exists; keybinding config is parsed but not applied at runtime — shortcuts are hardcoded in `AppShortcuts`.
- **docs/security.md**: Completed default rules table (added 9 missing entries). Added explicit source reference to `PermissionRuleset.defaults()`. Added note about fallback-to-`ask` behavior for tools without ruleset entries. Added evaluator source reference.
- **docs/diagrams/**: New mermaid-architecture diagrams directory created with 4 files:
  - `architecture-overview.md`: High-level data flow, session event pipeline, tool execution lifecycle (doom-loop=3 steps, correct flow order: cache→doom→exec→trunc), MCP connection architecture, config resolution chain (first-found-wins: project>global, no merge).
  - `sessions.md`: Drift ER diagram corrected (all column names/types match `database.dart`/`schema.dart`; added missing columns: `cost`, `tokensInput/Output/Reasoning/CacheRead/CacheWrite`, `permissionRules`, `seq`, `promptText`, `agent`, `modelRef`, `status`); state machine added missing events (`StepFailed`, `TaskStarted/Completed`, `TaskPart*`, `QuestionPart*`, `TodoPart*`); removed non-existent `ToolCalled` event; noted `SessionState` is `Equatable` not `freezed`; corrected `replayEvents()` signature and `projectEvent()` as pure function.
  - `tools.md`: Corrected conditional registration — `skill` is conditional (not unconditional); all 3 conditionals are independent `if` statements (not sequential); fixed doom-loop constant to 3 steps; corrected execution flow order.
  - `mcp.md`: Fixed `McpConnectionStatus` enum values (`connected/disabled/failed/needsAuth/needsClientRegistration`, not `Disconnected/Connecting/Connected/Error`); `McpOAuthConfig` corrected (`scope` singular not `scopes`, no `tokenUrl`, added `callbackPort` and `redirectUri`); `McpCallResult.content` corrected from `dynamic` to `List<McpContentPart>`; `McpConfig.defaultTimeout` corrected to `int?`; added missing `enabled`, `timeout`, `cwd`, `environment` on `McpServerConfig`.
- **docs/API.md** (additional corrections): Fixed `SessionRunner` section — `startSession()` is synchronous (not `Future<...>`); `startInitializedSession()` has `SessionID? sessionId` parameter; `runTaskInChild()` returns `Future<TaskChildResult>` (not `Future<void>`), has `SessionRunnerHolder? holder` parameter; removed non-existent `sdk.CancellationToken? abortSignal`; fixed Chinese character artifact (`Session跑了` → `SessionRunner`); corrected `SessionRunnerSession` fields — `sessionId` (not `id`), `createdAt` does not exist; added note that most session fields are private. Fixed `PermissionRequest` example — `permission: 'execute'` changed to `permission: 'bash'`. Fixed tool defaults table — `format`, `json_schema`, `apply_patch`, `invalid`, `plan_exit` have no `defaults()` entry (fallback `ask`); `skill` is conditional not unconditional; corrected unconditional count to 16.
- **docs/ENVIRONMENT.md**: Corrected Dart SDK version from 3.9 to 3.11.0 (matching `pubspec.yaml`).
- **docs/ROADMAP.md**: Created roadmap documenting completed milestones and future plans.
- **lib/l10n/app_en.arb / app_ru.arb**: Restored 19 missing localization keys to match the canonical 398-key set used by `app_uk.arb`, `app_zh.arb`, `app_ja.arb`, and `app_ar.arb`.
- **Documentation SDK versions**: Aligned Flutter SDK references to 3.44.0 across `README.md`, `AGENTS.md`, `ARCHITECTURE.md`, and `docs/ENVIRONMENT.md`.

### Added

- **Session Core + Event Sourcing**: Fully implemented Drift-backed event store with `SessionRunner`, `SessionRepository`, `EventStore`, `Projector`, and `SessionTree`. Event types include `SessionCreated`, `MessageAdded`, `TextStarted/Delta/Ended`, `ReasoningStarted/Delta/Ended`, `ToolStarted/Success/Failed`, `StepStarted/Ended/Failed`, `CompactionStarted/Ended`, `ChildSessionCreated`, `TaskStarted/Completed`. Tables: `events`, `sessions`, `messages`, `tool_results`, `context_epochs`. SessionID branded type (`ses_{uuid}`).
- **MCP Support**: `McpClientService` for connecting to local/remote MCP servers via `mcp_dart` package. Config models (`McpConfig`, `McpServerConfig`, `McpOAuthConfig`) and types (`McpToolInfo`, `McpCallResult`, `McpConnectionStatus`, `McpServerStatus`) in `lib/core/mcp/`. Supports StdioClientTransport for local and StreamableHttpClientTransport for remote servers.
- **Tool Execution Overhaul**: 16 built-in tools now registered — added `lsp`, `format`, `invalid`, `external_directory`, `json_schema`, `plan`, `question` (was unregistered). `ToolRegistry.toSDKTools()` integration. Doom-loop guard, cache deduplication (question tool cooldown), truncation service (2000 lines / 50KB).
- **Interactive Question System**: `QuestionPart` widget with `QuestionTool` (registered with cooldown dedup), permission pipeline via `ctx.askQuestion()`, `parsedAnswer` getter supporting JSON and plain text formats, `copyWith` immutability.
- **Freezed Session Models**: `SessionState` and `SessionMessage` now use `freezed_annotation` + `json_serializable` for immutable state management with JSON persistence. Generated via `build_runner`.
- **Session Providers**: Riverpod-based session state management (`session_providers.dart`) connecting UI to `SessionRunner` for session lifecycle operations.

- **MessagePart serialization fix**: All `MessagePart` subtypes are now serialized into `partsJson` on assistant message completion in `chat_screen_streaming.dart`. Previously only tool-related, todo, and task parts were persisted; text and reasoning parts are now included, fixing the text-disappearance bug when messages were reloaded.
- **Amazon Bedrock provider**: Switched `amazon_bedrock.dart` to `AuthType.aws` with `sdk: 'bedrock'`, enabling proper Bedrock catalog configuration.
- **Bedrock auth validation**: `model_resolver.dart` validates Bedrock auth requirements (`awsAccessKeyId`, `awsSecretAccessKey`, `awsRegion`) and throws a clear error when native AWS SigV4 integration is not yet implemented.
- **Provider options pattern**: `ProviderConfig` gained `buildProviderOptions()` and `buildProviderHeaders()` methods, for merging provider defaults, model metadata, and variant-specific fields.
- **Compaction orchestrator**: `CompactionOrchestrator` now receives a real `CompletionProvider` via constructor injection and no longer uses the stub implementation. Integrated with `SessionRepository` for event persistence across compaction cycles.

- **Tool Execution Loop**: 16 built-in tools (`bash`, `read`, `edit`, `write`, `glob`, `grep`, `webfetch`, `websearch`, `apply_patch`, `todowrite`, `task`, `question`, `invalid`, `external_directory`, `json_schema`, `plan`, `lsp`, `format`, `skill`) with `streamChatCompletion` integration via `SessionRunner`, max 5 steps per turn, auto-compaction on overflow.
- **Permission System**: Default ruleset (`read`/`glob`/`grep` = allow, rest = ask) with `chatorai.json` configuration, last-match-wins evaluator, Once/Always/Reject modal dialog.
- **@-mention Subagent System**: Quick agent invocation (`@explore`, `@general`, etc.) with fuzzy search dropdown above chat input. Agent registry with predefined subagents.
- **Tool Display**: Inline icons with state indicators (pending/running/completed/error), expandable outputs, standardized title formatting.
- **Tool Output Format**: Standardized output including `grep`'s `relative/path:lineNumber: content` format (1-indexed).
- **Chat Display Improvements**: MessagePart-based rendering (Text, Reasoning, ToolCall, ToolResult, Task, Question, Todo), synchronized `AnimatedSize` during streaming, robust auto-scroll.
- **Markdown Rendering**: Links without underlines for cleaner appearance.
- **ChatAppBar**: Model selector as clickable text button with uniform design across desktop and mobile.
- **Streaming UX**: Reasoning shimmer effect with separate Jennings dots; tool results preserved without truncation when expanded.
- **Error Handling**: Clear error messages for rate limits and failures; automatic retries with user-friendly feedback.
- **Compaction Service**: Automatic context summarization when token budget is exceeded.
- **Multi-Provider Registry**: UI for managing multiple AI providers (OpenRouter, local, custom endpoints).
- **Tool Registration Centralization**: All built-in tools registered exclusively in `built_in_tools.dart`; `question` tool registered; `skill` tool moved from separate provider.
- **Compaction Agent**: Changed mode to primary and hidden to true (internal agent).
- **Output Truncation**: Tool result outputs truncated to 2000 lines or 50KB to manage memory; expandable UI preserves full content in copy.
- **Utility Refactoring**: Moved `path_sandbox` utility to `lib/shared/utils/` for broader reuse.
- **Provider catalog 24h cache**: `discoverModels()` caches models for 24 hours in SharedPreferences. `cacheDuration` is a constructor parameter on `ProviderCatalogService`. Pass `forceRefresh: true` to bypass the cache.
- **ProviderIcon widget**: 22 SVG provider icons (ai302, alibaba, amazon, anthropic, azure, cloudflare, deepseek, gitlab, google, groq, huggingface, lmstudio, mistral, novita, nvidia, ollama, openai, openrouter, perplexity, speedai, vercel, vllm, xai) with theme-aware `ColorFiltered(BlendMode.srcIn)` rendering.
- **AddProviderDialog**: Provider icons in the dropdown list, auto-fill baseUrl on selection, Custom Provider entry with auto-generated ID.
- **ModelSelectionDialog**: Removed direct `Dio` calls; single source of truth via `catalog.discoverModels()`. Uses `List<ModelConfig>` instead of legacy `_ProviderModel`.
- **ProviderCatalogService**: Centralized catalog with `addCustomProvider()`, `removeCustomProvider()`, `getSelectedModelIds()`, `setSelectedModelIds()`, `clearSelectedModelIds()`. Custom providers persisted separately from built-in definitions.
- **Tests**: 43 unit tests for `ProviderCatalogService` covering cache hit/miss, forceRefresh, persistence across re-creation, custom provider lifecycle, non-Latin name fallback, and garbage key filtering.
- **Multi-provider support**: Connect to any OpenAI-compatible API endpoint.
- **Model discovery**: Fetch available models from provider `/models` endpoint.
- **Provider settings UI**: Configure API keys, base URLs, and enabled providers.

### Fixed

- **Android database hang**: `createFileDatabase()` in `lib/core/session/database.dart` no longer imports `xdg_paths_cli.dart`. The function now requires an explicit `dataDir` parameter and creates the directory inline with `Directory(dataDir).create(recursive: true)`. `session_db_provider.dart` imports the Flutter-aware `xdg_paths.dart` and passes `await XdgPaths.dataHomeAsync`, which resolves to the app's sandboxed support directory on Android. `bin/chatorai.dart` passes `XdgPaths.dataHome` from `xdg_paths_cli.dart`. Removed temporary `.timeout(10s)` debug wrapper from `chat_screen_messaging.dart`; removed unused `import 'dart:async'` from `chat_screen.dart`.

## Earlier development

### Added

- **`ChatoraiFontSizes.mono()`** factory with `size`, `color`, `weight`, `height`, `fontStyle`, `letterSpacing` params.
- **`ColorSchemeX`** theme extension with `muted` (0.5) and `dim` (0.7) for consistent alpha values.

### Changed

- All 17 monospace usages now use `ChatoraiFontSizes.monospaceFont` constant.
- 14 of 17 TextStyles now use `ChatoraiFontSizes.mono()` factory.
- Removed `Opacity(0.5)` wrapper around tool header — `_buildHeader` applies `muted` directly (fixes double-dimming).
- `Clipboard.setData` now awaited with try-catch error handling.
- LSP JSON parse errors now logged in debug mode instead of silently swallowed.
- Migrated `markdown_styles.dart` to use `app_theme.dart` exclusively.
- Removed abandoned `design_tokens/` directory (duplicate classes now consolidated).

### Fixed

- **lib/core/tools/tool_registry_provider.dart [COMPLETED]** — Fixed permission defaults merging: defaults are applied first, config overrides on top. When `config.permission` is non-empty, the merged ruleset preserves default `allow` rules for tools not explicitly overridden in the config (e.g., `websearch`, `webfetch`, `skill`, `lsp`, `task`, `question`, `todowrite`), preventing unintended fallback to `ask`.
- **lib/core/permission/permission_service.dart [REFACTORED]** — Removed cross-session persistence from "Always allow". Session scoping added via `_sessionId` field: `_approved` is cleared automatically when `sessionId` changes in `ask()`. Removed `SharedPreferences` import and persistence methods. Deprecated `clearRateLimitHistory()` as an alias for `clearSession()`.
- **lib/features/chat/presentation/widgets/parts/\_tool_title.dart [COMPLETED]** — Fixed path key detection by adding `file_path` fallback alongside `path` and `filePath`. Appended `$args` to the `write` case header. Bash header now shows `# $description` when a description exists, otherwise falls back to `toolName`. Fixed `skill` title to use `input['name']` instead of path. MCP/unknown tools now display `toolName [args]` when args are present.
- **lib/features/chat/presentation/widgets/parts/tool_result_part_widget.dart [COMPLETED]** — Complete terminal-style bash output redesign: uniform background (`Colors.black26` / `Colors.white38`), monospaced `$` prompt with command on the same row, `SingleChildScrollView` with `SelectableText` for output, and copy button with "✅ Copied" timer feedback. Bash body is always visible (not hidden behind `AnimatedCrossFade`); collapsed state renders `_bashPreview` (max 10 lines / 500 chars), expanded state renders full output. Standardized all tool header opacity to `0.5`. Unified terminal color across prompt, command, and result using `onSurface` at `alpha: 0.7`.
- **lib/core/tools/tool_registry.dart [COMPLETED]** — Fixed JSON wrapping in tool result streaming. `executeDynamic` now extracts the plain text output key from `Map<String, dynamic>` results (`'output'`, then `'message'`, then `toString()` fallback) before returning to the SDK. Eliminates the nested `{"output":"...","metadata":{...}}` JSON wrapping previously produced for all tool results (bash, read, grep, write, edit, etc.).

