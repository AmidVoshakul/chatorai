# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] - 2026-06-16

### Added

- **Provider catalog 24h cache**: `discoverModels()` caches models for 24 hours in SharedPreferences. `cacheDuration` is a constructor parameter on `ProviderCatalogService`. Pass `forceRefresh: true` to bypass the cache.
- **ProviderIcon widget**: 22 SVG provider icons (ai302, alibaba, amazon, anthropic, azure, cloudflare, deepseek, gitlab, google, groq, huggingface, lmstudio, mistral, novita, nvidia, ollama, openai, openrouter, perplexity, speedai, vercel, vllm, xai) with theme-aware `ColorFiltered(BlendMode.srcIn)` rendering.
- **AddProviderDialog**: Provider icons in the dropdown list, auto-fill baseUrl on selection, Custom Provider entry with auto-generated ID.
- **ModelSelectionDialog**: Removed direct `Dio` calls; single source of truth via `catalog.discoverModels()`. Uses `List<ModelConfig>` instead of legacy `_ProviderModel`.
- **ProviderCatalogService**: Centralized catalog with `addCustomProvider()`, `removeCustomProvider()`, `getSelectedModelIds()`, `setSelectedModelIds()`, `clearSelectedModelIds()`. Custom providers persisted separately from built-in definitions.
- **Tests**: 43 unit tests for `ProviderCatalogService` covering cache hit/miss, forceRefresh, persistence across re-creation, custom provider lifecycle, non-Latin name fallback, and garbage key filtering.

### Changed

- **ModelSelectionDialog**: Now accepts an optional `ProviderCatalogService` instance and delegates all model discovery to it instead of making direct HTTP requests.
- **ProviderIcon**: Deepseek reuses `huggingface-icon.svg` (no dedicated SVG). Fallback to `Icons.smart_toy_outlined` for unknown provider IDs.

### Fixed

- Removed duplicate iteration over `_selectedModelIds` in `_loadFromPrefs()` that could pick up keys from deleted providers.
- Added missing `await` on `updateProviderModels` in Save button handler of `ModelSelectionDialog`.
- Cache validity check in `discoverModels()` no longer requires `models.isNotEmpty` — empty model lists from failed discoveries are also cached.
- Non-Latin custom provider names now generate a fallback ID (`custom_<timestamp>`) instead of producing invalid identifiers.
- Removed unused `getProviderModels()` method from the catalog service.
- Fixed 4 SVG files (removed `<?xml` preamble for compatibility with `flutter_svg`).
- Converted `perplexity-ai-icon.svg` from UTF-16 to UTF-8 encoding.

### Developer

- `dart analyze` — **No issues found** across the entire project.

## [0.1.2] - 2026-05-26

### Added

- **Tool Execution Loop**: 8 built-in tools (`bash`, `read`, `edit`, `write`, `glob`, `grep`, `webfetch`, `websearch`) with `streamChatCompletion` integration, max 5 steps, auto-compaction on overflow.
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

## [0.1.1] - 2026-04-15

### Added

- **Multi-provider support**: Connect to any OpenAI-compatible API endpoint.
- **Model discovery**: Fetch available models from provider `/models` endpoint.
- **Provider settings UI**: Configure API keys, base URLs, and enabled providers.

## [0.1.0] - 2025-12-30

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
