# Commands Reference

**Last updated:** 2026-08-21

ChatORAI supports:

1. **CLI/Development Commands** — for building, testing, and running the app.
2. **@-Commands** — agent invocation (currently the only quick command implemented).
3. **Tool Commands** — built-in tools invoked by the AI.

---

## CLI Commands

These are shell commands used during development and deployment.

### Dependency & Generation

```bash
flutter pub get              # Fetch Dart dependencies
flutter gen-l10n             # Generate localization (only after editing lib/l10n/*.arb)
```

### Quality Assurance

```bash
flutter analyze             # Static analysis (lint). Excludes test/** per analysis_options.yaml.
flutter test                # Run unit and widget tests
flutter test --coverage     # With coverage report (requires lcov)
```

### Run & Build

```bash
# Development (hot reload)
flutter run -d linux
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d ios          # Requires macOS

# Release builds
flutter build linux --release
flutter build windows --release
flutter build apk --release  # Android
flutter build ios --release  # macOS
flutter build web --release
```

### Platform-specific Notes

- **Linux**: Install system libs first: `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`.
- **Windows**: Requires Visual C++ workload + Windows 10/11 SDK; CMake must be available.
- **iOS**: Requires macOS and Xcode; cannot build from Linux.

---

## Application CLI Commands

ChatORAI ships as a **single binary** that serves both the GUI and the CLI. The
entry point checks for CLI arguments first (`runCliIfRequested` in
`lib/core/cli/cli_commands.dart`); if a command matches, it runs and exits
**without starting the Flutter engine**. Run `chatorai` with no arguments to
launch the GUI.

### `chatorai` (no arguments)

Launches the ChatORAI GUI.

### `chatorai --help` / `-h`

Prints the main help text listing available commands.

### `chatorai --version` / `-v`

Prints the installed version, e.g.:

```
chatorai 0.1.1
```

### `chatorai stats [options]`

Aggregates and prints token usage, cost, and tool usage from the local session
database.

```
Usage: chatorai stats [options]

Options:
  --days <number>   Show stats for the last N days (0 = all time)
  --tools <number>  Show top N tools by usage (default: all)
  --help            Show this help
```

### `chatorai models [options]`

Lists all available models grouped by provider (from the local catalog cache
or built-in providers).

```
Usage: chatorai models [options]

List models available from the provider catalog.

Options:
  -p, --provider <id>  show only models for the given provider
  -h, --help           show this help
```

### `chatorai uninstall [options]`

Uninstall ChatORAI from the system and remove all related files. Installs into
per-user directories, so no administrator privileges are required.

```
Usage: chatorai uninstall [options]

uninstall chatorai from the system and remove all related files

Options:
  -c, --keep-config  keep configuration files
  -d, --keep-data    keep session data and snapshots
      --dry-run      show what would be removed without removing
  -f, --force, --yes skip confirmation prompts
  -h, --help         show help
```

### `chatorai mcp [subcommand]`

Manage Model Context Protocol (MCP) servers. Delegates to `runMcp` in
`lib/core/cli/mcp_cli.dart`.

```
Usage: chatorai mcp [command] [options]

Commands:
  (no args)       launch the interactive TUI menu
  list            list configured MCP servers and their status
  add <name> ...  add a new MCP server
  remove <name>   remove an MCP server
  enable <name>   enable an MCP server
  disable <name>  disable an MCP server
  help            show this help
```

### `chatorai upgrade [target]`

Upgrade to the latest released build (or a specific `target` version) from GitHub
Releases and install it to the user directory (`InstallPaths.installDir`, e.g.
`~/.local/share/chatorai`). No `sudo` is required — both the in-app upgrade and the standalone installer script install to a per-user directory. No Flutter SDK needed.

```
Usage: chatorai upgrade [target]

upgrade chatorai to the latest or a specific version

Positionals:
  target  version to upgrade to, e.g. '0.1.0' or 'v0.1.0'  [string]

Options:
  -f, --force, --yes  skip confirmation prompt
  -h, --help          show help
```

Equivalent to re-running the installer:

```
curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
```

---

## @-Commands (Agent Calls)

Type `@` followed by agent name to quickly invoke a subagent with additional context.

**Syntax:**

```
@agent_name <your prompt>
```

**Example:**

```
@explore review this function for security issues
```

or

```
review this function for security issues use @explore
```

**Available Agents:**

- `@general` — General-purpose assistant
- `@explore` — Fast agent for codebase exploration (read-only)
- `@name-subagent` - Custom subagents

  **UI:** Dropdown appears above chat input, filtered by fuzzy search. Selection inserts `@agent_name` and the subagent receives the full user message as context.

**Note:** `#` (file references) and `/` (slash commands) are planned for future releases but not yet implemented.

---

## Tool Commands (Built-in)

When the AI invokes tools, they appear inline in the chat stream with icons and status.

| Tool                       | Description                            | Default Permission |
| -------------------------- | -------------------------------------- | ------------------ |
| `shell`                    | Execute shell command                  | ask                |
| `read`                     | Read file contents                     | allow              |
| `edit`                     | Replace text in file                   | ask                |
| `write`                    | Create/overwrite file                  | ask                |
| `glob`                     | Find files by pattern                  | allow              |
| `grep`                     | Search file contents                   | allow              |
| `webfetch`                 | Fetch URL content                      | allow              |
| `websearch`                | Search web via SearXNG                 | allow              |
| `task`                     | Spawn subagent via `SessionRunner`     | deny                |
| `task_container`           | Run parallel subagent tasks, aggregate | allow              |
| `question`                 | Ask user question (with dedup)         | deny                |
| `todowrite`                | Update todo list                       | deny                |
| `skill`                    | Load specialized skill                 | allow              |
| `apply_patch`              | Apply unified diff                     | ask                |
| `lsp`                      | LSP hover/signature help               | allow              |
| `format`                   | Code formatting                        | ask                |
| `plan_enter`               | Switch to plan agent mode              | deny                |
| `plan_exit`                | Exit plan mode, switch to build agent  | deny                |
| `json_schema`              | JSON schema validation                 | ask                |
| `invalid`                  | Invalid tool placeholder               | ask                |
| `external_directory`       | Directory operations (builtin)         | ask                |
| `document_extract_pdf`     | Extract text from PDF                  | ask                |
| `document_extract_docx`    | Extract text from DOCX                 | ask                |
| `document_extract_xlsx`    | Extract text from XLSX                 | ask                |

**Conditionally registered:** `lsp` (when `LspService` available), `format` (when `FormatService` available), `skill` (when `SkillService` available). Total: 21 unconditional + up to 3 conditional (24 max).

**States:** `pending` (∼), `running` (spinner), `completed` (✓), `error` (✗). Tool results can be expanded to show full output.

**Note:** All tool outputs are truncated to 2000 lines or 50KB when displayed.

For the full tool reference with input schemas, see `docs/API.md` → Tools section.

---

## Configuration Commands

These are not interactive commands but JSON configuration options.

### chatorai.json Permission Section

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
}
```

**Rule fields:**

- `tool`: Tool name (e.g., `shell`, `edit`).
- `action`: Action string (usually `"execute"`).
- `resource`: Resource pattern (path, URL, regex). Wildcards supported via `*` and `?`.
- `permission`: `allow`, `deny`, or `ask`.

**Wildcard patterns:**

- `*` matches any sequence (except `/` for paths).
- `?` matches a single character.
- Patterns are matched against the tool's primary input (e.g., `path` for read/edit, `command` for shell).

For environment variables and system dependencies, see `docs/ENVIRONMENT.md`.
For API reference, see `docs/API.md`.
For architecture, see `ARCHITECTURE.md`.

## Diagrams

- [Subagent @-mention Routing](../diagrams/architecture-overview.md#high-level-data-flow)
- [Tool Execution Lifecycle](../diagrams/architecture-overview.md#tool-execution-lifecycle)
- [Install / Upgrade Flow](../diagrams/architecture-overview.md#install--upgrade-flow-linux)
