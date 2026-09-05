# Configuration

**Last updated:** 2026-08-21

ChatORAI can be configured via a JSON file (`chatorai.json`) to customize permissions, keybindings, provider settings, MCP servers, and more.

The configuration file location is resolved via `XdgPaths.configHome` (see `lib/shared/utils/xdg_paths.dart`). The search order is:

1. `<configHome>/chatorai.json` — user-global config (base layer)
2. `./.chatorai/chatorai.json` — project-specific config (overlay, **wins** on conflict)

**Typical paths by platform:**

| Platform | Config path                                                        |
| -------- | ------------------------------------------------------------------ |
| Linux    | `~/.config/com.chatorai.app/chatorai.json` (or `$XDG_CONFIG_HOME`) |
| macOS    | `~/Library/Application Support/com.chatorai.app/chatorai.json`     |
| Windows  | `%APPDATA%\com.chatorai.app\config\chatorai.json`                  |
| Mobile   | Sandboxed app support directory (no user-accessible path)          |

The directory name is derived from the `pubspec.yaml` `name:` field in the current working directory via regex (`^name:\s*(.+)$`), falling back to `chatorai` when the file is not present (e.g. globally installed CLI binary).

If both locations exist, they are deep-merged: the project config overrides the
global config's keys, while keys absent in the project config are inherited from
the global config. **List-valued keys** (`instructions`, `skills.paths`,
`skills.urls`) are **concatenated with duplicates removed** — so a project
config _adds_ to the global config's arrays rather than replacing them.

## JSON Schema

The file is validated against the JSON Schema defined in `lib/core/config/chatorai_schema.dart`. The `$schema` URL is:

```
http://json-schema.org/draft/2020-12/schema#
```

IDE autocomplete may use this schema if the `$schema` field is added to the file.

## Structure

```json
{
  "version": 1,
  "permission": { ... },
  "keybinding": { ... },
  "skills": { ... },
  "compaction": { ... },
  "formatter": { ... },
  "agent": { ... },
  "mcp": { ... },
  "tools": { ... },
  "instructions": [ ... ]
}
```

A complete, annotated example with every section populated is available at
[`chatorai.example.json`](../../chatorai.example.json) in the repository root.
It is **not** written automatically — copy the relevant sections into your own
`chatorai.json`. A freshly created config (written on first launch) contains
all sections as empty placeholders so you can see what is available.

### `version`

Integer indicating the configuration schema version. Currently `1`.

### `permission`

Controls which tools are allowed, denied, or require user confirmation. Supports two shapes:

- **String** — sets a default action for all permissions: `"allow"`, `"ask"`, or `"deny"`.
- **Object** — maps permission names to either a default action (string) or per-pattern actions (object).

Permission names correspond to tool IDs: `read`, `edit`, `write`, `shell`, `glob`, `grep`, `webfetch`, `websearch`, `task`, `todowrite`, `question`, `skill`, `lsp`, `doom_loop`, `external_directory`, etc.

#### Per-Pattern Rules

```json
{
  "permission": {
    "edit": {
      "*.env": "deny",
      "lib/**": "allow",
      "*": "ask"
    }
  }
}
```

Patterns use glob-like syntax and support home directory expansion (`~`, `$HOME`).

#### Default Rules

If no permission configuration is provided, the following defaults apply (source: `lib/core/permission/ruleset.dart` — `PermissionRuleset.defaults()`):

```json
{
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "webfetch": "allow",
    "websearch": "allow",
    "task": "deny",
    "question": "deny",
    "todowrite": "deny",
    "skill": "allow",
    "lsp": "allow",
    "shell": "ask",
    "edit": "ask",
    "write": "ask",
    "doom_loop": "ask",
    "external_directory": "ask",
    "plan_enter": "deny",
    "plan_exit": "deny"
  }
}
```

Tools without a ruleset entry (e.g. `apply_patch`, `format`, `invalid`, `json_schema`, `document_extract_pdf`, `document_extract_docx`, `document_extract_xlsx`) fall back to `ask` via the evaluator.

### `keybinding`

Customizes keyboard shortcuts. The config field is parsed and stored in
`ChatOrAIConfig.keybinding`, but the actual shortcuts are **hardcoded** in
`lib/core/keyboard/shortcuts.dart` (`AppShortcuts` widget). The configuration
is not currently applied at runtime — the `KeybindManager` class referenced in
earlier drafts does not exist. Future work: wire `chatorai.json` keybinding
settings into the shortcut system.

Example (for reference; not yet functional):

```json
{
  "keybinding": {
    "leader": "ctrl+x",
    "timeout": 2000,
    "bindings": {
      "session_child_next": "ctrl+right",
      "app_exit": "ctrl+q"
    }
  }
}
```

### `skills`

Configures skill discovery paths and remote sources. Skills provide specialized AI instructions and workflows.

```json
{
  "skills": {
    "paths": [".chatorai/skills/"],
    "urls": [
      "https://example.com/skills/index.json",
      {
        "url": "https://example.com/skills/index.json",
        "cache_ttl": 3600,
        "api_key": "..."
      }
    ]
  }
}
```

| Field   | Type       | Description                                |
| ------- | ---------- | ------------------------------------------ |
| `paths` | `string[]` | Directories to scan for `SKILL.md` files   |
| `urls`  | `array`    | Remote skill sources (URL to `index.json`) |

### `compaction`

Controls automatic context compaction when token budget is exceeded.

```json
{
  "compaction": {
    "auto": true,
    "prune": true,
    "buffer": 2000,
    "tail_turns": 2
  }
}
```

| Field         | Type   | Description                               |
| ------------- | ------ | ----------------------------------------- |
| `auto`        | `bool` | Enable automatic compaction               |
| `prune`       | `bool` | Prune old tool outputs                    |
| `buffer`      | `int`  | Token buffer before triggering compaction |
| `tail_turns`  | `int`  | Recent user-assistant pairs to keep verbatim |

> **Note:** The legacy `keep.tokens` key is accepted for backward compatibility but is ignored.

### `formatter`

Configures external code formatters (e.g. `dart format`).

```json
{
  "formatter": {
    "formatters": {
      "dart": {
        "disabled": false,
        "command": ["dart", "format", "--output=show"],
        "extensions": [".dart"]
      }
    }
  }
}
```

### `lsp`

Configures LSP (Language Server Protocol) diagnostics support. ChatORAI ships with 15 built-in servers for popular languages. Servers are started lazily when a matching file extension is first detected, and auto-installed if missing.

#### Enabling / Disabling

```json
{
  "lsp": true
}
```

- `lsp: true` (or omitting the section) — built-in servers are active.
- `lsp: false` — disables all LSP diagnostics, regardless of available servers.

#### Built-in Servers

| ID           | Language                | Extensions                                             | Auto-install                                |
| ------------ | ----------------------- | ------------------------------------------------------ | ------------------------------------------- |
| `dart`       | Dart                    | `.dart`                                                | —                                           |
| `typescript` | TypeScript / JavaScript | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`           | `npm install -g typescript-language-server` |
| `python`     | Python                  | `.py`, `.pyi`                                          | `pip install pyright`                       |
| `java`       | Java                    | `.java`                                                | —                                           |
| `kotlin`     | Kotlin                  | `.kt`, `.kts`                                          | —                                           |
| `go`         | Go                      | `.go`                                                  | —                                           |
| `rust`       | Rust                    | `.rs`                                                  | —                                           |
| `csharp`     | C#                      | `.cs`, `.csx`                                          | —                                           |
| `yaml`       | YAML                    | `.yaml`, `.yml`                                        | `npm install -g yaml-language-server`       |
| `shell`      | Shell / Bash            | `.sh`, `.bash`, `.zsh`, `.ksh`                         | `npm install -g bash-language-server`       |
| `clangd`     | C/C++                   | `.c`, `.cpp`, `.cc`, `.cxx`, `.c++`, `.h`, `.hpp`, ... | —                                           |
| `lua`        | Lua                     | `.lua`                                                 | —                                           |
| `markdown`   | Markdown                | `.md`, `.markdown`                                     | `npm install -g marksman`                   |
| `swift`      | Swift                   | `.swift`                                               | —                                           |
| `zig`        | Zig                     | `.zig`, `.zon`                                         | —                                           |

Servers without auto-install entries require manual installation on PATH before diagnostics are available.

#### Per-Server Overrides

```json
{
  "lsp": {
    "servers": {
      "my-typescript": {
        "command": "node_modules/.bin/typescript-language-server",
        "args": ["--stdio"],
        "extensions": [".ts", ".tsx"],
        "languageId": "typescript",
        "autoInstall": true
      },
      "legacy-lua": {
        "disabled": true
      }
    }
  }
}
```

| Field            | Type       | Description                                                                   |
| ---------------- | ---------- | ----------------------------------------------------------------------------- |
| `disabled`       | `boolean`  | If `true`, skip this server entirely.                                         |
| `command`        | `string[]` | Executable to launch. First element is the binary.                            |
| `args`           | `string[]` | Arguments passed to the binary.                                               |
| `extensions`     | `string[]` | File extensions this server handles (e.g. `[".ts", ".tsx"]`).                 |
| `languageId`     | `string`   | LSP language ID sent in `textDocument/didOpen`.                               |
| `environment`    | `object`   | Extra environment variables for the server process.                           |
| `initialization` | `object`   | Extra fields merged into the LSP `initialize` params.                         |
| `autoInstall`    | `boolean`  | If `true`, attempt package-manager install if the command is missing on PATH. |

### `agent`

Configures per-agent overrides and customizations. Each key is an agent name (e.g., `general`, `explore`, custom subagents).

```json
{
  "agent": {
    "general": {
      "prompt": "Override the default system prompt for the general agent.",
      "max_steps": 10
    },
    "my-custom-agent": {
      "disabled": true,
      "hidden": false
    }
  }
}
```

| Field         | Type     | Description                                                         |
| ------------- | -------- | ------------------------------------------------------------------- |
| `prompt`      | `string` | Override the agent system prompt                                    |
| `name`        | `string` | Override the agent display name                                     |
| `description` | `string` | Override the agent description shown in UI                          |
| `model`       | `string` | Override the default model for this agent                           |
| `temperature` | `number` | Override the default sampling temperature                           |
| `permission`  | `string` | Override default permission for this agent (`allow`, `ask`, `deny`) |
| `disabled`    | `bool`   | Remove this agent from registry                                     |
| `hidden`      | `bool`   | Hide this agent from UI                                             |
| `max_steps`   | `int?`   | Override max steps for agent execution. `null` = unlimited          |
| `maxSteps`    | `int?`   | Alias for `max_steps`. `null` = unlimited                           |

### `mcp`

Configures external MCP (Model Context Protocol) servers. These servers provide additional tools that appear as native built-in tools during AI conversations.

```json
{
  "mcp": {
    "default_timeout": 30000,
    "servers": {
      "my-server": {
        "type": "local",
        "command": "npx",
        "args": ["-y", "my-mcp-server"],
        "cwd": "/home/user",
        "environment": { "NODE_ENV": "production" },
        "timeout": 30000
      },
      "remote-server": {
        "type": "remote",
        "url": "https://api.example.com/mcp",
        "headers": { "Authorization": "Bearer ..." },
        "oauth": {
          "client_id": "...",
          "client_secret": "...",
          "scope": "...",
          "callback_port": 8080,
          "redirect_uri": "http://localhost:8080/callback"
        }
      }
    }
  }
}
```

**Server types:**

| Type   | Required fields   | Optional fields                                             |
| ------ | ----------------- | ----------------------------------------------------------- |
| local  | `command`, `args` | `cwd`, `environment`, `enabled`, `timeout`, `type: "local"` |
| remote | `url`             | `headers`, `oauth`, `enabled`, `timeout`, `type: "remote"`  |

Tools discovered from MCP servers are registered into the `ToolRegistry` and participate in the tool execution pipeline alongside built-in tools.

Servers may also be declared in the **flat layout** — each key directly under
`"mcp"` is a server name (no `"servers"` wrapper):

```json
{
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "."]
    }
  }
}
```

Both layouts are equivalent and may be mixed.

### `tools`

Global tool visibility overrides. Glob patterns map to `true` (allow),
`false` (deny), or the strings `"allow"`, `"ask"`, `"deny"`.

```json
{
  "tools": {
    "shell": "ask",
    "websearch": "allow",
    "read": true
  }
}
```

### `instructions`

A list of instruction files or URLs merged into the system prompt. Each entry is one of:

- A **relative glob** resolved from the project root, e.g. `.chatorai/instructions/*.md`
- A **filename** searched upward from the project root, e.g. `AGENTS.md`
- A **`~/`** path expanded to the user's home directory
- An **absolute path** (globbed by its basename inside its directory)
- An **http(s) URL** (fetched and inlined)

Project-level `instructions` are concatenated with global `instructions`
(duplicates removed). The resolved text is inserted into the system prompt as
`Instructions from: <path>\n<content>` blocks.

```json
{
  "instructions": [
    ".chatorai/instructions/*.md",
    "AGENTS.md",
    "https://example.com/company-rules.md"
  ]
}
```

### `provider`

Declares custom LLM providers. Each key is a provider ID; the
declared provider overrides any built-in provider with the same ID. All config
providers are treated as **OpenAI-compatible** — chatorai always uses the
OpenAI-compatible adapter based on `baseURL`, so no `npm` field is needed.

```json
{
  "provider": {
    "custom-openrouter": {
      "name": "OpenRouter (custom)",
      "options": {
        "baseURL": "https://openrouter.ai/api/v1",
        "apiKey": "{env:OPENROUTER_API_KEY}",
        "temperature": 0.1
      },
      "models": {
        "openrouter/owl-alpha": {
          "name": "Owl Alpha",
          "limit": { "context": 1048576, "output": 262144 }
        }
      }
    },
    "groq": {
      "options": { "apiKey": "{env:GROQ_API_KEY}" },
      "models": {
        "openai/gpt-oss-20b": { "name": "GPT OSS 20B" }
      }
    }
  }
}
```

Notes:

- **`apiKey`** supports `{env:VAR}` substitution — the value is resolved from the
  `VAR` environment variable at startup. If the variable is not set in the
  process environment, chatorai additionally reads it from your shell rc files
  (`~/.bashrc`, `~/.zshrc`, `~/.profile` on desktop) so the key is found even
  when the app is launched from a GUI launcher. If still unset, the provider
  becomes key-less (`AuthConfig.none`). The literal `"public"` also yields a
  key-less provider. A literal key string also works.
- **`options.baseURL`** points at the OpenAI-compatible `/v1` endpoint.
- **`options.temperature`** sets the default sampling temperature for the provider.
- **`models`** lists models by ID. Each may set `name` (display name) and
  `limit` (`context` = max context tokens, `output` = max output tokens).
  Config providers do **not** support automatic model discovery — every model
  you want to use must be listed explicitly under `models`. If a model is
  omitted, it will not be available.
- Config providers are **read-only**: they are applied on top of the built-in
  catalog at startup and are not written back to app storage. They are only
  available on desktop/CLI builds where `chatorai.json` is read from disk.

## Validation

On startup, the configuration is loaded and validated. If the JSON is malformed or does not conform to the schema, an error is thrown and the default configuration is used. Users will see an error message in the UI.

## Examples

### Minimal (use defaults)

```json
{
  "version": 1
}
```

### Restrict Shell and Edit

```json
{
  "version": 1,
  "permission": {
    "shell": "deny",
    "edit": "deny"
  }
}
```

### Allow Read/Glob/Grep Only

```json
{
  "version": 1,
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "*": "deny"
  }
}
```

## Tips

- Use `"*"` as a pattern to match all paths.
- Patterns are case-sensitive on Linux/macOS and case-insensitive on Windows.
- The `always` permission granted via UI is stored in memory only and resets on app restart.
- For advanced use, combine string defaults and pattern objects within the same permission section.

## Diagrams

- [Config Resolution Chain](../diagrams/architecture-overview.md#config-resolution-chain)
- [Permission Evaluator Pipeline](../diagrams/architecture-overview.md#tool-execution-lifecycle)
