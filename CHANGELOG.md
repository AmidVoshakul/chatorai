# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

 - **Auto-Approve settings (file-access permissions UI)**:
   - New `AutoApproveScreen` (Settings → Auto-Approve) exposes the 14 permission categories from `PermissionRuleset.defaults()` (external_directory, shell, read, edit, write, glob, grep, webfetch, websearch, doom_loop, skill, lsp, task, todowrite) with a per-category `Default(<built-in>)/Allow/Ask/Deny` dropdown and a collapsible Exceptions block (path patterns for file categories, command patterns for `shell`). `question`/`plan_enter`/`plan_exit` are hidden internal categories.
   - `auto_approve_provider.dart` (`AutoApproveNotifier`): loads effective rules from the merged `chatorai.json` `permission` section, saves via `ConfigWriter.upsertPermissionSection`, and invalidates `configProvider` so changes apply immediately. `Default` omits the key (inherits `PermissionRuleset.defaults()`); explicit actions are written as a string or `{"*": action, ...exceptions}` map.
   - Project vs Global scope toggle, hidden on mobile (`_supportsProjectScope`), mirroring the MCP/instructions providers.
   - Localization keys added across all 6 ARB files (`autoApproveTitle`, `autoApproveSubtitle`, `scopeGlobal`, `scopeProject`, `defaultInherit/Allow/Ask/Deny`, `exceptionsTitle`, `addPath`, `addCommand`, `cancel`, `save`).
 - **Live config reload (reactivity)**:
   - `ConfigWatcher` watches the parent directory of the global (`<configHome>/chatorai.json`, all platforms) and project (`<cwd>/.chatorai/chatorai.json`, desktop only) config files and, on change, calls `ref.invalidate(configProvider)`. Cascade: `skillServiceProvider` re-applies rules via `PermissionService.replaceDefaultRules` and `toolRegistryProvider` rebuilds `ToolRegistry`, so external edits to `chatorai.json` take effect without a restart (like opencode/kilocode). Directory watching survives atomic rename-based writes (`ConfigWriter` writes via temp+rename). Debounced (~300 ms); missing directories are tolerated.
   - `PermissionService.replaceDefaultRules` now marks the service as seeded so live reloads actually update effective defaults; session-scoped grants are preserved.
 - **Link confirmation dialog**:
   - Bottom-sheet confirmation when tapping `http`/`https` links in chat (`TextPartWidget`, `ReasoningPartWidget`, `table_block.dart`). Non-http schemes (`javascript:`, `data:`, `file:`, `tel:`, `mailto:`, empty) are silently ignored.
   - New utility `lib/shared/utils/link_launcher.dart`: `isHttpHttpsUrl(String?)`, `enum LinkLaunchResult { opened, invalidScheme, failed }`, `launchExternalLink(String href, {launcher})` with DI-friendly `launcher` parameter (defaults to `url_launcher.launchUrl` with `LaunchMode.externalApplication`).
   - New widget `lib/features/chat/presentation/widgets/link_confirm_sheet.dart`: `showLinkConfirmSheet(BuildContext, {required String href, launcher})` using `PremiumSheetShell`, `PremiumHandle`, `PremiumAvatar` (`Icons.open_in_new`), `KeyboardHandlerDialog` (Enter/Escape), `premiumGhostButton`/`premiumPrimaryButton`, `SnackbarUtils.showCopySnackBar` and `SnackbarUtils.showErrorSnackBar`. `isDismissible: true`.
   - Localization keys added across 6 ARB files: `confirmOpenLink` ("Are you sure you want to open:"), `linkCancel` ("Cancel"), `linkOpen` ("Open"), `linkCopied` ("Link copied"), `linkOpenFailed` ("Failed to open link").
   - Dependency added: `url_launcher: ^6.3.1`.
 - **Context usage ring indicator and popup**:
  - Ring chip in `ChatInputStatusBar`: 14px diameter, 2px stroke, color-coded based on calibrated `usableRatio` (`warningRatio * usableRatio` / `hardRatio * usableRatio`). Green below warning threshold, amber between warning and hard, red above hard.
  - Context popup on desktop (hover, 300ms delay) and mobile (tap): shows context summary (`contextMessages`), segmented progress bar (used/free/buffer), auto-compact threshold (`contextAutoCompactAt`), instruction sources breakdown (`contextInstructions` with agent prompt, user system prompt, instruction blocks), usage breakdown (`contextUsageBreakdown`) with input/output/tool tokens, tool calls count, cache read/write (if >0), and spent USD (`contextSpentLabel`) if applicable. Compact session button with spinner during execution.
  - New provider `sessionContextUsageProvider` in `lib/features/chat/data/providers/session_context_usage_provider.dart`: aggregates context usage from the latest assistant message (`usedTokens`, `outputTokens`, `reasoningTokens`, `cacheReadTokens`, `cacheWriteTokens`, `toolTokens`, `toolCallsCount`), calculates `contextLength` (from latest assistant message or selected model), `buffer` (from compaction config or `OverflowDetector`), `usable` ratio, instruction sources, and `spentUsd` (session total across all assistant messages, per-message pricing from catalog or selected model, free models yield 0).
- **Token/cache math refinement**:
  - `UsageCacheTokens` and `UsageRawData` models in `lib/core/llm/usage_cache_mapper.dart`: unified extraction of cache read/write and reasoning tokens from provider-specific usage maps (OpenAI Chat Completions, OpenAI Responses, DeepSeek, Anthropic-compatible gateways).
  - `tokensCacheIncludedInInput` flag on `AssistantMessage`: indicates whether cache tokens are already included in `tokensInput` to avoid double-counting. Serialized in `toJson`/`fromJson` and included in equality/hashCode.
  - `UsageCallback` typedef: `void Function(int input, int output, int cacheRead, int cacheWrite, int reasoning, bool cacheIncludedInInput)` (6 arguments). Task tool discards the 6th argument via `_`.
  - `ChatAiService.resolveUsage`: simplified — `cacheIncludedInInput` is always resolved from raw usage or SDK data; dead branch removed.
- **Localization updates**:
  - Removed obsolete `contextSpent` key from all 6 ARB files.
  - Added `contextSpentLabel` ("Spent"), `contextCacheRead` ("Cache read"), `contextCacheWrite` ("Cache write"), `contextUsageBreakdown` ("Usage breakdown"), `contextPromptTokens` ("Input tokens"), `contextOutputTokens` ("Output tokens"), `contextToolTokens` ("Tool tokens"), `contextAutoCompactAt` ("Auto-compact at {percent}% · {buffer} tokens").
- **Tool system refactor**:
  - Renamed `bash` tool to `shell` across implementations, tests, and documentation.
  - Added `document_extract` tool family: `createDocumentExtractPdfTool()`, `createDocumentExtractDocxTool()`, `createDocumentExtractXlsxTool()` for extracting text from PDF, DOCX, XLSX files.
  - Added `task_container` tool for parallel subagent task execution with aggregated results.
  - Removed dead code: `permission_bridge.dart`, `secure_file_service.dart`.
- **Session and context improvements**:
  - Child (task/subagent) sessions are excluded from parent context popup (only primary sessions with `parentId == null` are counted; their cost is already reflected in the parent prompt).
  - Ring chip thresholds calibrated via `usableRatio`: `warningRatio` and `hardRatio` are multiplied by `usableRatio` to account for reserved buffer. `autoCompactPercent` is derived from `warningRatio * 100`.
  - `OverflowDetector` and `BackgroundCompactionThresholds` used for context limit and buffer calculation.
- **UI/UX improvements**:
  - Removed text token counter from under assistant messages; replaced with ring chip.
  - Removed `cumulativeTokens`/`contextLength` plumbing from `ActionRow`, `ChatMessageBubble`, `AssistantMessageBubble`, `UserMessageBubble`, `UserMessageEdit`, `ChatMessages`, and `SessionContextWindow`.
  - Removed `tokenDisplay` utility from `lib/shared/utils/format_utils.dart`; kept `formatTokenCount`.
  - Updated `ChatInputStatusBar` layout: `Padding > Row(Expanded(Wrap), ring chip)`.
  - Added `workspace_dialog.dart` for directory/workspace management.
  - Added `settings_window.dart` for desktop settings UI.
  - Added `app_theme.dart` and `theme_extensions.dart` for centralized theming.
  - Added `shimmer_mask.dart` for loading states.
  - Added `premium_sheet.dart` for premium feature prompts.
- **LSP expansion**:
  - Built-in LSP servers expanded to 15 (dart, typescript, python, java, kotlin, go, rust, csharp, yaml, shell, clangd, lua, markdown, swift, zig).
  - LSP auto-install via platform package managers (npm, cargo, brew, pip, go) when server command is missing.
  - `lsp` config section in `chatorai.json`: global `enabled` flag plus per-server overrides.
- **MCP improvements**:
  - MCP Marketplace with 15 preconfigured remote servers, search, category filters, premium cards.
  - MCP add dialog supports environment, headers, Raw JSON tab, token authentication.
  - MCP server types accept `http`/`https`/`sse` as aliases for `remote`, `stdio` for `local`.
 - **Keyboard shortcuts**:
   - Global shortcut handler for desktop (workspace switching, etc.).
   - User-configurable keyboard shortcut system: extended `KeyActivator` with `shift`/`alt`/`meta` modifiers, `fromString()`/`format()` round-trip, and updated `matches()` logic. Added `KeyboardShortcut.copyWith()` for runtime override.
   - `KeybindingNotifier` (`keybinding_provider.dart`): Riverpod `Notifier` managing user keybinding overrides, persisted via `ConfigWriter.upsertKeybindingSection()` into `chatorai.json`. Supports `setBinding`, `resetToDefaults`, conflict detection, and bare-key validation.
   - `KeyboardShortcutsScreen` (`keyboard_shortcuts_screen.dart`): premium settings UI with capture widget, conflict detection, reset-to-defaults, and desktop-first capture (mobile view-only).
   - Registered in `settings_screen.dart` (mobile) and `settings_window.dart` (desktop). Exported via `lib/providers.dart`.
   - Localization strings added across all 6 ARB files; `flutter gen-l10n` run.
   - Tests: `keybinding_service_test.dart` (KeyActivator round-trip, matches, copyWith), `keybinding_provider_test.dart` (load/set/reset/conflicts/validation), `shortcut_handler_test.dart` (existing, still green), `test_global_shortcut_handler_workspace.dart` (existing, now compiles after `currentAgentProvider` export fix).
- **Workspace support**:
  - Working directory override per session/project.
  - Workspace provider for directory management.
- **Tests**: numerous new unit and widget tests for context usage, ring chip, tools, sessions, LSP, MCP, permissions, etc.

### Changed

- **ChatAiService**: migrated to `ai_sdk_dart` v2; `streamChatCompletion` uses new SDK types.
- **SessionRunner**: refactored for better event sourcing and child session handling.
- **Permission system**: `shell` tool default changed from `allow` to `ask`; `DangerousCharacterPolicy` softened to `review` for safe metacharacters (`|`, `>`, `<`, `&`).
- **Model provider**: `recentModels` strip added to model selection screen.
- **Compaction service**: refactored with `CompactionOrchestrator` and `BackgroundCompactionService`.
- **File-access safety net**:
  - `path_sandbox.dart`: `PathDeniedException` + `isHardDenied` block dangerous paths (`/etc/shadow`, `~/.ssh`, `windows/system32`, `authorized_keys`); `resolveSafePath` no longer throws for non-dangerous external paths.
  - `tool_path_resolve.dart`: shared `resolveToolPath` helper centralizes path resolution + `external_directory` ask + `PathDeniedException` handling across read/write/edit/glob/grep/apply_patch/document_extract/external_directory tools (no duplicated resolution logic).

### Fixed

- **Tool-output storage path**: Truncated tool output was previously written to `getApplicationDocumentsDirectory()` (`~/Documents/chatorai/` on Linux), which caused `Path denied` errors when the model later tried to read it back via `read`/`grep`/`glob` because Documents is outside the project root and the path sandbox rejected it. Output is now written to the cross-platform data directory (`~/.local/share/chatorai/tool-output` on Linux, XDG-compliant on other desktops, sandboxed Documents on mobile). The `read`/`grep`/`glob` tools now accept this directory as a managed read root (symlink-safe via `FilesystemBoundary.resolve()`), so the model can read back its own truncated output without permission prompts.
- **Android database hang**: `createFileDatabase()` in `lib/core/session/database.dart` no longer imports `xdg_paths_cli.dart`. The function now requires an explicit `dataDir` parameter and creates the directory inline with `Directory(dataDir).create(recursive: true)`. `session_db_provider.dart` imports the Flutter-aware `xdg_paths.dart` and passes `await XdgPaths.dataHomeAsync`, which resolves to the app's sandboxed support directory on Android. `bin/chatorai.dart` passes `XdgPaths.dataHome` from `xdg_paths_cli.dart`.
- **Linter warnings**: Resolved unused imports and dangling library doc comments introduced during refactoring. `flutter analyze` reports zero issues.
- **SelectionArea crash during streaming**: `lib/features/chat/presentation/widgets/chat_messages.dart` wrapped the message `ListView.builder` in a single `SelectionArea`. When `itemCount` changed mid-stream while the user had an active text selection, the `MultiSelectableSelectionContainerDelegate` indices became stale and Flutter threw `currentSelectionStartIndex < selectables.length` (`selectable_region.dart`). The `SelectionArea` is now keyed on `itemCount`, so it is rebuilt from scratch (dropping any active selection) whenever the list length changes. Selection/copy of message and code content is preserved; per-bubble `SelectableText`/`SelectionArea` (code blocks, tool results, speech overlay) are unaffected. Added widget tests guarding the fix.

### Documentation

- **docs/API.md**: Added `sessionContextUsageProvider`, `UsageCallback`, `UsageCacheTokens`, `UsageRawData`, `extractUsageRawData`, `resolveUsage`. Updated `AssistantMessage` fields (added `tokensCacheRead`, `tokensCacheWrite`, `tokensCacheIncludedInInput`, `contextLength`, `agent`, `isCompactionSummary`). Updated built-in tool count from 18 to 21 unconditional tools (added `document_extract_pdf`, `document_extract_docx`, `document_extract_xlsx`, `task_container`). Removed references to deleted `ChatStorageService`.
- **docs/COMMANDS.md**: Updated tool list to include `document_extract` family and `task_container`. Corrected unconditional tool count to 21.
- **docs/CONFIGURATION.md**: Added `document_extract` tools to fallback `ask` list. Updated permission defaults table.
- **docs/ENVIRONMENT.md**: Updated `ai_sdk_dart` and related package versions from `^1.x` to `^2.0.0` to match `pubspec.yaml`.
- **docs/diagrams/tools.md**: Updated unconditional tool count from 18 to 21; added `document_extract` family and `task_container` to registry diagram.
- **ARCHITECTURE.md**: Removed references to deleted files (`permission_bridge.dart`, `secure_file_service.dart`, `chat_repository_impl.dart`, `background_job_provider.dart`, `chat_message_export.dart`, `permission_dialog.dart`, `scrollable_action_buttons.dart`, `assistant_header.dart`, `patch_body.dart`, `diff_line.dart`). Added new files (`session_context_usage_provider.dart`, `chat_input_status_bar.dart`, `document_extract.dart`, `lsp_diagnostics_format.dart`, `tool_call_tracker.dart`, `workspace_provider.dart`, `workspace_runtime.dart`, `cwd_override.dart`, `background_compaction_service.dart`, `global_shortcut_handler.dart`, `keyboard_shortcut.dart`, `shortcuts.dart`, `premium_sheet.dart`, `shimmer_mask.dart`, `settings_window.dart`, `settings_modal.dart`, `settings_about_section.dart`, `settings_accessibility_section.dart`, `settings_appearance_section.dart`, `app_loading_screen.dart`, `android_storage_permission.dart`, `app_theme.dart`, `theme_extensions.dart`, `providers.dart`, `diff_body.dart`, `edit_body.dart`, `write_body.dart`, `diff_parser.dart`, `premium_confirm_sheet.dart`, `workspace_dialog.dart`, `workspace_switch_confirm_sheet.dart`, `session_context_window.dart`, `chat_screen_scroll.dart`, `chat_stream_actions.dart`). Updated tool layer description to reflect 21 unconditional + 3 conditional tools.

### Fixed

 - **Recursive external-directory permissions (no more per-file dialog spam)**:
   - Root cause: `external_directory` permission was requested with the exact file path as both `patterns` and `always`, so an "Always" grant covered only that single file — every subsequent file in the same directory re-prompted the user.
   - `tool_path_resolve.dart`, `shell.dart` (working-dir + preflight `externalDirs`), and `external_directory.dart` now request `dirname(path)/*` (a directory glob). Because the wildcard engine (`lib/core/permission/wildcard.dart`, `dotAll: true`) treats `*` as recursive, a single "Always" grant covers the whole directory tree (`/dir/*` matches `/dir/file` and `/dir/sub/file`).
   - **Over-broad guard**: a new pure helper `externalDirectoryGlobPatterns(directory, {workspacePath, fallback})` in `lib/shared/utils/path_sandbox.dart` returns the exact `fallback` path (no `/*`) when the directory is the filesystem root (`/`) or an ancestor of the workspace, preventing an accidental `/*` (whole-disk) grant. DRY: the same helper is used by all three call sites.
   - `read.dart` and `document_extract.dart` `read` permission asks now pass `always: ['*']` (matching opencode `read.ts`), so the first "Always" on a read dialog grants universal read instead of re-prompting per file.
   - Tests: added unit tests for `externalDirectoryGlobPatterns` (file → `dirname/*`; FS root → exact path; above-workspace → exact path; recursive coverage verified via `wildcard.match`) and an integration test in `test_tool_path_resolve_test.dart`; updated `test_external_directory_tool.dart` and `test_shell_ast_scanner.dart` assertions to the new glob patterns.

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
