# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- **Slash command core extraction**:
  - `lib/core/commands/` module with `SlashCommand` model, `SlashCommandCatalog` (built-ins + `fromCommandInfo` + filter + `SlashCommandLocalizations` abstract), `SlashCommandExecutor` (`/compact`, `/new`, `/thinking` via callbacks), `SlashCommandNavigator` (cyclic nav), `SkillTemplateRenderer` (template rendering, `$N`/`$ARGUMENTS`/quoted args/`[Image N]`/`$0` guard), and `SkillCommandResolver`.
  - `command_parser.expandCommandTemplate` now delegates to `SkillTemplateRenderer`.
  - GUI handler (`slash_command_handler.dart`) and `send_message_handler.dart` are thin orchestrators via `SlashCommandExecutor`.
- **WorkspacePort abstraction**:
  - `lib/core/workspace/workspace_port.dart` (`WorkspacePort` interface), `workspace_runtime.dart` (moved from `shared/`), `process_workspace_port.dart` (default).
  - `workspacePortProvider` in `core/config` wired to `RiverpodWorkspacePort` override in `main.dart`.
- **Shared tool registry factory**:
  - `lib/core/tools/tool_registry_factory.dart` (`createToolRegistry` shared by app and terminal).
  - Thin GUI wrapper in `gui/features/chat/data/providers/tool_registry_provider.dart`.
- **Core chat services**:
  - `lib/core/chat/services/` with `chat_ai_service.dart`, `chat_cancellation.dart`, `chat_retry_service.dart`, `tool_call_tracker.dart`.
- **New tests**:
  - `test/core/workspace/test_workspace_port_test.dart`
  - `test/core/tools/test_tool_registry_factory_test.dart`
  - `test/core/commands/` (slash_command, catalog, executor, skill_template_renderer, skill_command_resolver)
- **Slash command UX improvements**:
  - `/thinking` command toggles `expandReasoningByDefault` in `themeProvider`, clears input without snackbar feedback.
  - Cyclic navigation for command and skills popups (`navigateCommandPopup`/`navigateSkillsPopup` wrap around).
  - Full localization of built-in slash-command descriptions across 6 languages (`slashCommandSkills`, `slashCommandNew`, `slashCommandClear`, `slashCommandCompact`, `slashCommandHelp`, `slashCommandUndo`, `slashCommandRedo`, `slashCommandSessions`, `slashCommandModels`, `slashCommandTheme`, `slashCommandThinking`).
  - `SlashCommandNavigator` helper class with unit tests (`test_slash_command_navigator.dart`).
- **Unified chat auto-scroll**:
  - `ChatMessagesConstants.followBand` (`150.0`) and `userScrolledAwayBand` (`25.0`) are the single source of truth for scroll thresholds across all chat views.
  - `ChatScrollFollowController` drives auto-scroll identically for parent (`ChatMessagesArea`) and child (`SessionContextWindow`) sessions via `noteGrowth()` / `handleNotification()`.
  - `chatIsNearBottom(controller, {threshold})` helper centralizes "is the user at the bottom" logic.
  - `ChatMessages` now accepts an optional external `followController`; when provided, the same controller is shared between parent and child windows.
  - Widget test added: `test_chat_messages_auto_scroll_widget_test.dart` covers parent auto-scroll, scroll-away suppression, Home/End shortcuts, unmount cleanup, and child-session auto-scroll.
- **Support the Project**:
  - New `AboutSupportSection` widget (`lib/gui/features/settings/widgets/about_support_section.dart`) shared by the About dialog and the About settings section.
  - Three full-width `OutlinedButton` actions: Star on GitHub (`https://github.com/AmidVoshakul/chatorai`), Become a Sponsor (`https://github.com/sponsors/AmidVoshakul`), Share your thoughts (`https://github.com/AmidVoshakul/chatorai/issues`).
  - GitHub icon rendered via `SvgPicture.asset('assets/provider/github.svg')` with theme-aware `ColorFiltered` recolor, matching the existing provider card pattern.
  - Links opened through the existing `launchExternalLink` utility (`lib/shared/utils/link_launcher.dart`).
  - 5 new localization keys added across all 6 languages (`supportProjectTitle`, `supportProjectSubtitle`, `supportStarOnGitHub`, `supportBecomeSponsor`, `supportShareThoughts`).

### Changed

- **Phase A layout refactoring**:
  - New top-level layout: `lib/core/` (shared business logic, pure Dart), `lib/gui/` (all Flutter: features, shared theme/widgets/utils, keyboard), `lib/tui/` (Nocterm terminal UI, `mcp_tui.dart`), `lib/l10n/` (single localization source, 6 languages, untouched), `lib/shared/` (only pure utilities now), `lib/main.dart` + `lib/providers.dart` stay top-level as composition root.
  - Domain chat models moved `gui/features/chat/data/models/*` → `core/chat/` (`chat_models.dart` + `chat/*`).
  - `global_shortcut_handler` moved `core/keyboard` → `gui/keyboard`.
  - `tool_registry_provider` moved `core/tools` → `gui/features/chat/data/providers/` (GUI wrapper).
  - `chat_ai_service` + cancellation/retry/tracker moved `gui/services` → `core/chat/services`.
  - `secure_storage_service` + `secret_storage` back in `shared/`.
  - `message_utils` barrel → `gui/shared/`.
  - `core/core.dart` barrel extended (chat, commands, workspace, tools).
- **Popup visual polish**:
  - Selected items in `CommandPopup` and `SkillsPopup` now use a gradient background (`ChatoraiColors.orangeJyice` → `theme.colorScheme.primaryContainer`).
  - `PopupItemDefaults` in `app_theme.dart` centralizes selected-item decoration, icon color, name/description text styles, and dim overlay color.
  - `AgentMentionPopup` migrated to shared `PopupItemDefaults` styles.
  - Chat content dims with `ChatoraiColors.black30` when any input popup is open; chat input remains fully visible.
- **Chat input button styling**:
  - Action, stop, and agent buttons now accept an optional `BorderRadius` parameter, defaulting to circular when omitted.
  - Desktop and mobile chat inputs use unified rounded-square buttons with `ChatoraiBorderRadius.md` (`12px`) for a cohesive premium look.
  - Removed the desktop text-field border so the input area aligns visually with the action buttons and feels lighter.
  - Reduced desktop text-field vertical padding to `ChatoraiSpacing.xs` for tighter visual height alignment with the 44px buttons.
- **Event schema**: Added `ToolStarted` event (`session_runner.dart`, `events.dart`, `event_store.dart`, `projector.dart`) emitted alongside `ToolCalled` when a tool begins execution. `projectEvent` projects it as `AssistantTool(state: ToolState.pending)`.

### Fixed

- **Phase A bugfixes**:
  - `/new` + `/compact` + `/thinking` unified between palette and typed send via `SlashCommandExecutor`.
  - Partial-match popup filters by first word only.
  - `$0` placeholder guard in skill template renderer.
  - Null-check after skill service load in `SlashCommandHandler`.
  - Magic numbers for `/skills` parsing replaced with constants.
  - Double filtering removed from `CommandPopup`.
  - Chat input desktop buttons fixed to 44px (Row stretch → end alignment).
  - Workspace test teardown restores `Directory.current`.
- **Popup visibility propagation**: `onPopupVisibilityChanged` callback threaded from `ChatScreen` → layout widgets → `ChatLayoutContent` → dim overlay, ensuring chat content dims correctly when any input popup is open.
- **Tool-card display order**: Tools no longer appear mid-thought. Reasoning blocks are closed before tool cards are emitted, and subsequent reasoning after a tool becomes a separate block — restoring the visual order `thought → tool → tool → thought → answer`.
- **Child-session scroll and auto-scroll stability**:
  - Removed auto-scroll-to-bottom on session open for child windows; pages now respect the user's saved scroll position when swiping between siblings.
  - `PageController.keepPage: true` + `AutomaticKeepAliveClientMixin` preserve scroll position across sibling page changes.
  - `_ensureTitle` race condition fixed: a monotonic request ID prevents stale async responses from overwriting the active title during fast swipes.
  - `SessionContextWindow` now accepts an explicit `followController`, eliminating implicit internal instances in child sessions.
  - `ChatMessages._signature` now hashes all messages (`id`, `content`, `isComplete`, `role`) so mid-list edits invalidate the cache correctly.
  - `ChatScrollFollowController.noteGrowth()` schedules the snap via a post-frame callback with coalescing (`_scrollScheduled`), preventing multiple redundant scrolls per frame.
  - Bottom snap uses `animateTo(30ms)` instead of `jumpTo()` so the scroll tracks new content dimensions after layout, eliminating the text-vs-bubble desync during streaming and after tool cards appear.

### Tests

- `test/core/workspace/test_workspace_port_test.dart`: WorkspacePort interface and default implementation tests.
- `test/core/tools/test_tool_registry_factory_test.dart`: Shared tool registry factory tests.
- `test/core/commands/`: New test suite for slash-command core:
  - `test_slash_command_test.dart`
  - `test_slash_command_catalog_test.dart`
  - `test_slash_command_executor_test.dart`
  - `test_skill_template_renderer_test.dart`
  - `test_skill_command_resolver_test.dart`
  - `test_command_parser.dart`
  - `test_command_registry.dart`
  - `test_command_service.dart`
- `test_slash_command_navigator.dart`: 6 tests covering cyclic navigation, empty-list safety, and selection matching.
- `test_thinking_command.dart`: 2 tests verifying `/thinking` toggles `expandReasoningByDefault` via `themeProvider` and is selectable from the navigator.
- `session_runner_streaming_test.dart`: Updated all deferred-tool-card tests to assert immediate emission; added tests for buffered post-tool reasoning flush, parallel tool waves, and `ToolStarted` ordering.
- `session_runner_sdk_repro_test.dart`: Updated kilo-style SSE reproduction to expect 3 reasoning parts (pre-tool, buffered post-tool, step-2 thought) with tool cards emitted immediately after the first thought.
- `test_tool_card_after_reasoning.dart`: Removed unused `events.dart` import; assertions now cover immediate tool-card emission with `ReasoningEnded` before `ToolCalled`.

### Documentation

- **CHANGELOG.md**: Documented the deferred-tool-card removal and `ToolStarted` event addition.

## [0.1.1]

### Added

- **Skills marketplace and management UI**: Skills management screen with install/uninstall, marketplace catalog with 100+ bundled skills, skill writer for custom skills, instructions management with per-project/global instructions, MCP server management with add/edit/delete and marketplace integration.
- **CLI expansion**: New `chatorai` CLI commands for install/uninstall/path management, MCP TUI, config writer with atomic writes, instructions resolver, agents file service, spinner and style utilities, cross-platform install/uninstall scripts for Linux/macOS/Windows.
- **Session and context improvements**: Child-session routing for parallel task delegation, active session spinner in sidebar and workspace, session context usage provider with ring indicator and popup, token/cache math refinement (`UsageCacheTokens`, `UsageRawData`, `tokensCacheIncludedInInput`), compaction orchestrator with background service.
- **Permission and security**: Auto-approve settings screen with 14 permission categories, live config reload via `ConfigWatcher`, wildcard-based `external_directory` permissions with recursive glob patterns, `PathDeniedException` + `isHardDenied` for dangerous paths, `DangerousCharacterPolicy` softened to `review`.
- **Link and tool UX**: Link confirmation dialog for http/https links, document extraction tools (PDF/DOCX/XLSX), tool output truncation with managed read-back directory, tool title/path detection improvements, shell output redesign with terminal-style rendering.
- **Localization**: 6-language ARB updates (en/ru/uk/zh/ja/ar) with 398+ keys, restored missing localization keys, new strings for auto-approve, context usage, MCP, skills, settings.
- **Provider and model UX**: Provider catalog with 24h cache, custom provider management, model selection dialog with recent models strip, 22 SVG provider icons, Amazon Bedrock provider with auth validation, provider options pattern for headers/body merging.
- **Tests**: 100+ new unit/widget/integration tests covering CLI, config, permissions, MCP, skills, sessions, tools, models, path sandbox, secret storage, task container, tool title widget, session runner holder.

### Changed

- **ChatScreen consolidation**: Merged 8 part files into single `chat_screen.dart`; `ChatActions` now handles compaction; `ChatAiService` migrated to `ai_sdk_dart` v2.
- **Permission system**: `shell` default changed from `allow` to `ask`; `read`/`glob`/`grep` remain `allow`; `question`/`todowrite`/`task` default to `ask`; `external_directory` uses recursive glob patterns.
- **Tool registry**: 21 unconditional + 3 conditional tools; `tool_output_persistence.dart` and `tool_permission.dart` removed; execution now uses `ToolExecutor` with doom-loop guard and cache deduplication.
- **Session event schema**: Added `ToolStarted`, `TaskPartStarted/Completed/Error`, `QuestionPartStarted/Answered`, `StepStarted/Ended/Failed`, `CompactionStarted/Ended`, `ChildSessionCreated`; `SessionRunnerSession` tracks explicit part IDs.

### Fixed

- **Retry backoff**: `onChunkReceived` now triggered for all stream events (reasoning, tool results, tool errors, start/end signals), preventing exponentially increased delays mid-stream.
- **Android database hang**: `createFileDatabase()` no longer imports `xdg_paths_cli.dart`; requires explicit `dataDir` parameter; Flutter-aware `xdg_paths.dart` used on Android.
- **Tool-output storage**: Truncated output written to cross-platform data directory instead of `getApplicationDocumentsDirectory()`; `read`/`grep`/`glob` tools accept managed read roots.
- **SelectionArea crash**: `SelectionArea` keyed on `itemCount` to prevent stale selection indices during streaming.
- **Recursive external-directory permissions**: Single "Always" grant covers entire directory tree via `dirname(path)/*` glob; over-broad whole-disk grants prevented.

### Documentation

- **docs/API.md**: Added `sessionContextUsageProvider`, `UsageCallback`, `UsageCacheTokens`, `UsageRawData`, `extractUsageRawData`, `resolveUsage`. Updated `AssistantMessage` fields, tool count to 21, `SessionRunner` signatures, permission defaults.
- **docs/COMMANDS.md**: Updated tool list and permission table to match code; removed redundant input schema column.
- **docs/CONFIGURATION.md**: Added `skills`, `compaction`, `formatter` config sections; completed default rules table; fixed `provider` section.
- **docs/ENVIRONMENT.md**: Updated `ai_sdk_dart` to `^2.0.0`, corrected Dart SDK to 3.11.0.
- **docs/ROADMAP.md**: Created roadmap documenting completed milestones and future plans.
- **docs/diagrams/**: New mermaid architecture diagrams (overview, sessions, tools, mcp) with corrected ER diagrams and state machines.
- **ARCHITECTURE.md**: Updated file lists, tool layer description, removed references to deleted files.

## [0.1.0]

First public release.

### Added

- One-command prebuilt install for Linux (`install_chatorai.sh`), Windows (`install_chatorai.ps1`/`.bat`), and macOS (`.dmg`). No Flutter SDK required for end users.
- `chatorai upgrade [target]` command for in-app updates (downloads latest release from GitHub and installs to `/usr/local/lib/chatorai`).

- **Session Parts Provider**: New `sessionPartsProvider` for reactive streaming of both parent and child sessions, replacing the legacy `streamingMessageProvider` with a granular part-based approach.

### Changed

- **Shell tool security policy**: Changed default `shell` permission from `allow` to `ask` in `PermissionRuleset.defaults()`. Removed `DangerousCharacterPolicy` from `lib/core/tools/built_in/shell.dart` that was overly aggressive in flagging safe shell metacharacters (`|`, `>`, `<`, `&`) as `highRisk`. Safe commands (`find`, `echo hello | cat`, etc.) now run without prompts; medium/high-risk commands (`echo foo; echo bar`, `rm -rf /`, blocked executables) trigger permission dialogs. Nothing is harshly denied — only `ask` or `allow`.
- **Sensitive env file protection**: Added `*.env` and `*.env.*` to default `read` permission rules as `ask`. Added `ArgumentPatternPolicy` in shell tool to detect `cat/less/more/head/tail/vi/vim/nvim/nano .env` commands as `highRisk` review. `.env.example` remains `allow`.
- **Explicit Part IDs**: `SessionRunnerSession` now tracks explicit part IDs for text, reasoning, and tool-related content segments.
- **QuestionOption Model**: New `QuestionOption` model supports richer interactive questions with `multiple` selection support.
- **ShortcutHandler & AppShortcuts**: Centralized keyboard shortcut management widget.
- **SecureFileService**: New service for filesystem boundary enforcement and external directory access authorization.
- **PermissionBridge**: New bridge integrating tool-specific permission requests with the existing `PermissionService`.
- **TruncationService**: Prevents context overflow by truncating large tool outputs and saving them to the managed data directory.
- **ChatRetryService**: Infinite retries for retryable errors with exponential backoff and `Retry-After` header support.
- **Enhanced SessionEvent Schema**: Support for task-specific parts and improved metadata persistence.
- **AssistantQuestion Multiple Selection**: `AssistantQuestion` now supports `multiple` boolean for multi-select questions.
- **ChatScreen Refactor**: Split into focused files (`chat_screen_ai.dart`, `chat_screen_edits.dart`, `chat_screen_build.dart`, `chat_screen_messaging.dart`, `chat_screen_management.dart`, `chat_screen_navigator.dart`, `chat_screen_part_placeholder.dart`).
- **Widget Parts Split**: Tool body and display widgets separated into individual files:
  `_shell_body_widget.dart`, `_read_body_widget.dart`, `_grep_body_widget.dart`,
  `_write_body_widget.dart`, `_edit_body_widget.dart`, `_lsp_body_widget.dart`,
  `_patch_body_widget.dart`, `_generic_body_widget.dart`, `_diff_line_widget.dart`,
  `_webfetch_body_widget.dart`, `_tool_icon.dart`, `_tool_title.dart`.
  49 new tests added.
- **Widget Refactoring Phase 2**: Extracted shared formatting utilities to `lib/shared/utils/format_utils.dart` with `formatTokenCount`, `tokenDisplay`, `formatDurationMs`, `formatDuration`, and `shellPreview` to eliminate code duplication across `action_row.dart`, `task_part_widget.dart`, and `reasoning_part_widget.dart`.
- **UserMessageEdit Widget**: Extracted user message editing interface from `ChatMessageBubble` into a dedicated `lib/features/chat/presentation/widgets/parts/user_message_edit.dart` file, reducing `ChatMessageBubble` responsibility to message dispatching only.
- **Unified ContinuationSuggestions**: Removed duplicate `_ContinuationSuggestions` from `assistant_bubble.dart`; now uses the shared `ContinuationSuggestions` from `action_menu_button.dart`.
- **Renamed tool body widgets** (removed underscore prefix for consistency):
  - `_shell_body_widget.dart` → `shell_body.dart`
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
- **Eliminated duplicate `shellPreview`**: Removed duplicate implementation from `tool_result_part_widget.dart`; now imports and uses the shared version from `format_utils.dart`.
- **Centralized duration formatting**: `task_part_widget.dart` and `reasoning_part_widget.dart` now use shared `formatDurationMs(int?)` and `formatDuration(Duration)` from `format_utils.dart`.
- **Empty directory cleanup**: Confirmed empty `lib/features/chat/presentation/widgets/chat/` directory already removed.

### Fixed

- **Linter warnings**: Resolved unused imports and dangling library doc comments introduced during refactoring. `flutter analyze` reports zero issues.
- **Unused imports cleaned up**: Removed stale imports from `chat_message_bubble.dart`, `user_message_edit.dart`, and `format_utils.dart`.
- **Shell tool security policy**: Changed command_shield policies in `lib/core/tools/built_in/shell.dart` from immediate `deny` to `review` (ask-permission flow). `DangerousCharacterPolicy` now returns `review` at `highRisk` level; `ArgumentPatternPolicy` for `chmod` and redirect patterns now return `review`; `ExecutableBlockListPolicy` uses `onMatch: CommandDecision.review`; replaced `RiskThresholdPolicy` with custom `_ReviewOnlyPolicy` that never denies and always asks permission for `mediumRisk` and above. Removed duplicate blocked-executable deny check. Verified with `dart analyze` (clean) and `flutter test test/integration/shell_integration_test.dart` (15/15 passed). Goal: commands such as `curl`, `rm -rf`, and `npm` now trigger a permission dialog instead of being immediately blocked.

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
- **docs/API.md** (additional corrections): Fixed `SessionRunner` section — `startSession()` is synchronous (not `Future<...>`); `startInitializedSession()` has `SessionID? sessionId` parameter; `runTaskInChild()` returns `Future<TaskChildResult>` (not `Future<void>`), has `SessionRunnerHolder? holder` parameter; removed non-existent `sdk.CancellationToken? abortSignal`; fixed Chinese character artifact (`Session跑了` → `SessionRunner`); corrected `SessionRunnerSession` fields — `sessionId` (not `id`), `createdAt` does not exist; added note that most session fields are private. Fixed `PermissionRequest` example — `permission: 'execute'` changed to `permission: 'shell'`. Fixed tool defaults table — `format`, `json_schema`, `apply_patch`, `invalid`, `plan_exit` have no `defaults()` entry (fallback `ask`); `skill` is conditional not unconditional; corrected unconditional count to 16.
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

- **Tool Execution Loop**: 16 built-in tools (`shell`, `read`, `edit`, `write`, `glob`, `grep`, `webfetch`, `websearch`, `apply_patch`, `todowrite`, `task`, `question`, `invalid`, `external_directory`, `json_schema`, `plan`, `lsp`, `format`, `skill`) with `streamChatCompletion` integration via `SessionRunner`, max 5 steps per turn, auto-compaction on overflow.
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

- **Retry backoff not resetting mid-stream**: `ChatRetryService.onChunkReceived` was only triggered for `StreamTextTextDeltaEvent`. After receiving reasoning deltas, tool results, or tool errors, the retry attempt counter was not reset, causing subsequent retries to use exponentially increased delays (16–32 s) instead of starting from the base delay. Fixed by calling `onChunkReceived` for all meaningful stream events (`reasoning-delta`, `tool-result`, `tool-error`, `reasoning-start/end`, `tool-input-*`, `usage`, `source`, `file`, `start-step`, `finish-step`, `finish`).

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
- **lib/features/chat/presentation/widgets/parts/\_tool_title.dart [COMPLETED]** — Fixed path key detection by adding `file_path` fallback alongside `path` and `filePath`. Appended `$args` to the `write` case header. Shell header now shows `# $description` when a description exists, otherwise falls back to `toolName`. Fixed `skill` title to use `input['name']` instead of path. MCP/unknown tools now display `toolName [args]` when args are present.
- **lib/features/chat/presentation/widgets/parts/tool_result_part_widget.dart [COMPLETED]** — Complete terminal-style sjell output redesign: uniform background (`Colors.black26` / `Colors.white38`), monospaced `$` prompt with command on the same row, `SingleChildScrollView` with `SelectableText` for output, and copy button with "✅ Copied" timer feedback. Shell body is always visible (not hidden behind `AnimatedCrossFade`); collapsed state renders `_shellPreview` (max 10 lines / 500 chars), expanded state renders full output. Standardized all tool header opacity to `0.5`. Unified terminal color across prompt, command, and result using `onSurface` at `alpha: 0.7`.
- **lib/core/tools/tool_registry.dart [COMPLETED]** — Fixed JSON wrapping in tool result streaming. `executeDynamic` now extracts the plain text output key from `Map<String, dynamic>` results (`'output'`, then `'message'`, then `toString()` fallback) before returning to the SDK. Eliminates the nested `{"output":"...","metadata":{...}}` JSON wrapping previously produced for all tool results (shell, read, grep, write, edit, etc.).
