# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Documentation

- **docs/API.md**: Fixed tool permission table (7 tools had wrong defaults: `webfetch`, `websearch`, `task`, `todowrite`, `question`, `skill`, `lsp` were `ask` in docs but `allow` in code). Corrected total tool count from 16 to 19 (16 unconditional + 3 conditional). Added `ReasoningPart` field documentation with `durationMs` persistence details. Fixed `McpClientService` line (was truncated). Removed duplicate Internal APIs entries. Updated top-level schema sections to match actual `chatorai_schema.dart` (added `skills`, `compaction`, `formatter`; removed stale `provider`).
- **docs/COMMANDS.md**: Updated tool permission table to match corrected data. Removed redundant input schema column (now references API.md). Removed incorrect "5-min cooldown" mention for `question` tool (dedup mechanism differs).
- **docs/ENVIRONMENT.md**: Updated example JSON — removed stale `provider` block, added `skills`, `compaction`, `formatter` sections. Fixed MCP server type enum (`stdio`/`http` → `local`/`remote`). Added `default_timeout` to MCP section.
- **docs/configuration.md**: Added missing `skills`, `compaction`, `formatter` config sections. Completed default rules table (added 9 missing entries: `task`, `question`, `todowrite`, `skill`, `lsp`, `external_directory`; clarified `apply_patch`/`format`/`invalid` fallback behavior). Updated MCP server type enum. Fixed `provider` section (removed "Currently not used"). Fixed `keybinding` status from "planning" to "implemented".
- **docs/security.md**: Completed default rules table (added 9 missing entries). Added explicit source reference to `PermissionRuleset.defaults()`. Added note about fallback-to-`ask` behavior for tools without ruleset entries. Added evaluator source reference.

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
- **Provider options pattern**: `ProviderConfig` gained `buildProviderOptions()` and `buildProviderHeaders()` methods, following the OpenCode pattern for merging provider defaults, model metadata, and variant-specific fields.
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

## [0.1.0] - 2026-06-28

### Added

- Multiple AI models support via OpenRouter
- Voice input with speech-to-text
- Camera and image attachment support
- Advanced Markdown rendering with syntax highlighting
- Dark/Light theme support with Ubuntu design
- Multi-language support (English, Russian, Ukrainian, Chinese, Japanese, Arabic)
- RTL language support
- Local chat history storage
- Code block rendering with syntax highlighting
- Streaming responses from AI
- Welcome suggestions for new chats
- Chat navigation with markdown headings
- Adaptive token management for long conversations

### Changed

- Migrated to Riverpod 3.x for state management
- Optimized performance for weak devices
- Improved UI responsiveness

### Fixed

- Various bug fixes and improvements
