# Security Model

**Last updated:** 2026-08-21

ChatORAI implements a defense-in-depth security approach, covering permission controls, secret handling, logging sanitization, and secure communication.

## Permission System

ChatORAI uses a granular permission system to control tool access. Permissions are defined in `chatorai.json` and evaluated at runtime.

### Default Rules

Out of the box, the following defaults apply (source: `lib/core/permission/ruleset.dart` — `PermissionRuleset.defaults()`):

| Permission           | Default Action |
| -------------------- | -------------- |
| `read`               | `allow`        |
| `glob`               | `allow`        |
| `grep`               | `allow`        |
| `webfetch`           | `allow`        |
| `websearch`          | `allow`        |
| `task`               | `deny`        |
| `question`           | `deny`        |
| `todowrite`          | `deny`        |
| `skill`              | `allow`        |
| `lsp`                | `allow`        |
| `shell`              | `ask`          |
| `edit`               | `ask`          |
| `write`              | `ask`          |
| `doom_loop`          | `ask`          |
| `external_directory` | `ask`          |
| `plan_enter`         | `deny`         |
| `plan_exit`          | `deny`         |

Tools without an explicit ruleset entry (`apply_patch`, `format`, `invalid`, `json_schema`, `document_extract_pdf`, `document_extract_docx`, `document_extract_xlsx`) fall back to `ask` via the permission evaluator (`lib/core/permission/evaluator.dart`).

### Configuration

Users can customize permissions by creating a `chatorai.json` file in:

- User-global config (highest priority): `<configHome>/chatorai.json` (resolved via `XdgPaths.configHome`)
- Project-specific config (fallback): `<project>/.chatorai/chatorai.json`

Where `<configHome>` follows platform conventions (see `lib/shared/utils/xdg_paths.dart`):

- Linux: `~/.config/<package>/` (or `$XDG_CONFIG_HOME`)
- macOS: `~/Library/Application Support/<package>/`
- Windows: `%APPDATA%\<package>\config\`

The file is validated against a JSON schema for correctness.

Example:

```json
{
  "version": 1,
  "permission": {
    "read": "allow",
    "shell": "deny",
    "edit": {
      "*.env": "deny",
      "lib/**": "allow"
    }
  }
}
```

### Evaluation

- Rules are evaluated in order; the **last matching rule** wins.
- Pattern matching uses glob-like syntax with home directory expansion (`~`, `$HOME`).
- If no rule matches (and no entry in `PermissionRuleset.defaults()`), the fallback is `ask`.
- When a permission is `ask`, the user is prompted via a modal dialog.
- The evaluator implementation is in `lib/core/permission/evaluator.dart` → `evaluate()`.

### User Prompts

When a tool requires permission, the app shows a dialog with three options:

- **Allow once** — grant permission for this invocation only.
- **Always allow** — add a temporary rule for the current session (cleared on restart).
- **Reject** — deny the request; the tool execution fails.

The "Always allow" choice is confirmed with a secondary dialog to prevent accidental grants.

## Secret Handling

- **API keys** are never stored in the repository. The `.env` file is for development only and is gitignored.
- In release builds, users enter their API key and base URL through the app's settings UI. Values are stored in platform-specific secure storage (Keychain/Android Keystore/Windows DPAPI/Linux LibSecret) or, if unavailable, in `SharedPreferences` with **AES-256-GCM encryption**.
- The AES-256-GCM fallback (`PrefsSecretStorage` in `lib/shared/utils/secret_storage.dart`) stores the encryption key alongside the encrypted data. This provides obfuscation against casual inspection but **not full security** — a user with access to the device can extract both the key and the ciphertext. This is by design: the fallback ensures functionality on systems without a keyring daemon (e.g. headless Linux, TTY sessions), while the OS keyring remains the security boundary when available.
- The fallback is backed by the `cryptography` and `cryptography_flutter` packages.
- On Linux systems without a running keyring daemon (e.g., antiX, server Linux, TTY sessions), the app transparently falls back to encrypted SharedPreferences so it remains fully functional without requiring `gnome-keyring` or other system packages.
- API keys are transmitted only over HTTPS (TLS) to the respective provider endpoints.
- The codebase avoids logging any secrets. Log statements do not include raw API keys, tokens, or authentication headers.

## Logging Sanitization

To prevent accidental leakage of sensitive data, the app sanitizes error messages and logs:

- Error messages are truncated to a safe length (max 500 characters) and stripped of stack traces before being shown to users.
- Internal logs (via `Logger`) do not include request/response bodies that might contain secrets.
- The `ChatErrorUtils.formatError` function cleans up common error patterns and removes technical details that could expose implementation specifics.

## Network Security

- All external communication uses TLS/HTTPS.
- The app validates server certificates (default Dio behavior).
- Rate limiting is respected by parsing `Retry-After` headers and backing off accordingly.

## MCP Trust Boundary

Tools discovered from external MCP servers are treated as **untrusted**:

- MCP tool execution follows the same permission rules as built-in tools (`ask` by default).
- MCP server configurations are stored in `chatorai.json` under the `mcp` section.
- Stdio transport: server processes are spawned with restricted environment variables.
- HTTP transport: TLS enforced for remote endpoints; OAuth tokens stored in `SecureStorage`.

## Session Data

- Session data is persisted in a Drift SQLite database at `dataHome/chatorai.db`.
- No session content is transmitted to external servers (only to the configured AI provider API).
- `SessionState` and `SessionMessage` use immutable `Equatable` models with `json_serializable` for consistent JSON serialization.

## Session Management

- Session identifiers are randomly generated (UUID v4) and never logged in debug mode.
- Refresh tokens, if used, are stored in secure storage and rotated periodically.
- Every API request includes authentication headers that are validated by the server.

## Input Validation

- All user inputs (including file paths, patterns, and commands) are validated before processing.
- The permission system acts as a gatekeeper for filesystem access, preventing unauthorized reads/writes outside allowed patterns.
- Tool inputs are sanitized to remove potentially harmful content (e.g., extremely long messages, error patterns).

## Diagrams

- [Permission Evaluation Pipeline](../diagrams/architecture-overview.md#tool-execution-lifecycle)
- [Permission Ruleset ER](../diagrams/tools.md#tool-registry-conditional-registration)
