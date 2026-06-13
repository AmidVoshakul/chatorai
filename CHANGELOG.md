# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Retry & Rate Limiting**: Unbounded exponential backoff retry with jitter, `Retry-After` header support, and context preservation across retries.
- **Permission System**: Default rules (`read`, `glob`, `grep` allow; others ask) with user-configurable `chatorai.json` and Once/Always/Reject prompts.
- **Tool Output Format**: Standardized output, including `grep`'s `relative/path:lineNumber: content` format (1-indexed).
- **Tool Display**: Inline icons with state indicators (pending/running/completed/error), expandable outputs, and standardized title formatting.
- **@-mention System**: Quick agent invocation (`@explore`, `@general`, etc.) with fuzzy search dropdown above chat input. `#` file references and `/` slash commands are planned for future.
- **Chat Display Improvements**: MessagePart-based rendering (Text, Reasoning, ToolCall, ToolResult, Task, Question, Todo), synchronized `AnimatedSize` during streaming, and robust auto-scroll.
- **Markdown Rendering**: Links no longer have underlines for a cleaner look.
- **ChatAppBar**: Model selector is now a clickable text button with uniform design across desktop and mobile.
- **Streaming UX**: Reasoning shimmer effect with separate Jennings dots; tool results preserved without truncation when expanded.
- **Error Handling**: Clear error messages for rate limits and failures; automatic retries with user-friendly feedback.
- **Compaction Service**: Automatic context summarization when token budget is exceeded (already integrated).
- **Multi-Provider Registry**: UI for managing multiple AI providers (OpenRouter, local, custom endpoints).
- **Tool Registration Centralization**: All built-in tools now registered exclusively in `built_in_tools.dart`; `question` tool registered; `skill` tool moved from separate provider.
- **Compaction Agent**: Changed mode to primary and hidden to true (internal agent).
- **Output Truncation**: Tool result outputs truncated to 2000 lines or 50KB to manage memory; expandable UI preserves full content in copy.
- **Utility Refactoring**: Moved `path_sandbox` utility to `lib/shared/utils/` for broader reuse.

## [1.0.0] - 2025-12-30

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
