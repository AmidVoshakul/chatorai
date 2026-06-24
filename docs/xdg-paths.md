# XdgPaths — Platform-Aware Application Paths

**Source:** `lib/shared/utils/xdg_paths.dart`

## Why XdgPaths Exists

Previously, the application used hardcoded paths (`~/Documents/chatorai/`, `~/.local/share/chatorai/`) and a static `appDirName` constant. This broke on:

- **Linux** when users customized `XDG_*_HOME` environment variables
- **macOS** where `~/Documents` is not the conventional location for app data
- **Windows** where paths use backslashes and `APPDATA`/`LOCALAPPDATA`
- **Mobile** (Android/iOS) where apps are sandboxed and must use `path_provider`

XdgPaths resolves the directory name dynamically from the application's bundle ID at runtime via `package_info_plus`, ensuring correct paths regardless of how the app is distributed or installed.

## How `init()` Works

`XdgPaths.init()` must be called **once** at application startup, before any sync getter is accessed:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await XdgPaths.init();
  // ... rest of app initialization
}
```

The method:

1. Calls `PackageInfo.fromPlatform()` to read the bundle ID (e.g. `com.chatorai.app`)
2. Validates the name (rejects empty, slashes, `..`)
3. Caches it in a static field
4. Subsequent calls are no-ops (safe to call multiple times)

If `init()` has not been called, all getters fall back to the literal string `chatorai` and emit a warning log.

## Directory Layout by Platform

### Linux (XDG Base Directory Specification)

| Getter       | Default Path                | Env Variable       |
| ------------ | --------------------------- | ------------------ |
| `dataHome`   | `~/.local/share/<package>/` | `$XDG_DATA_HOME`   |
| `configHome` | `~/.config/<package>/`      | `$XDG_CONFIG_HOME` |
| `cacheHome`  | `~/.cache/<package>/`       | `$XDG_CACHE_HOME`  |
| `stateHome`  | `~/.local/state/<package>/` | `$XDG_STATE_HOME`  |

### macOS (Apple Convention)

| Getter       | Path                                       |
| ------------ | ------------------------------------------ |
| `dataHome`   | `~/Library/Application Support/<package>/` |
| `configHome` | `~/Library/Application Support/<package>/` |
| `cacheHome`  | `~/Library/Caches/<package>/`              |
| `stateHome`  | `~/Library/Application Support/<package>/` |

### Windows (MS Convention)

| Getter       | Path                              |
| ------------ | --------------------------------- |
| `dataHome`   | `%APPDATA%\<package>\`            |
| `configHome` | `%APPDATA%\<package>\config\`     |
| `cacheHome`  | `%LOCALAPPDATA%\<package>\cache\` |
| `stateHome`  | `%APPDATA%\<package>\state\`      |

### Mobile (Android / iOS)

| Getter            | Path                                               |
| ----------------- | -------------------------------------------------- |
| `dataHomeAsync`   | `getApplicationSupportDirectory()` (sandboxed)     |
| `configHomeAsync` | Same as data (mobile has no separate config home)  |
| `cacheHomeAsync`  | `getTemporaryDirectory()/<package>/cache`          |
| `stateHomeAsync`  | `getApplicationSupportDirectory()/<package>/state` |

## Data / Cache / Config Separation

The four base directories follow the semantic split:

- **`dataHome`** — Persistent application data (session database, tool outputs). Safe to back up.
- **`configHome`** — User configuration files (`chatorai.json`, global skills, agents). Safe to back up.
- **`cacheHome`** — Non-essential cached data (model lists, URL-skill cache). Safe to delete.
- **`stateHome`** — Runtime state (non-essential, safe to discard). Not critical.

### Async vs Sync Getters

| Sync (desktop only) | Async (all platforms) |
| ------------------- | --------------------- |
| `dataHome`          | `dataHomeAsync`       |
| `configHome`        | `configHomeAsync`     |
| `cacheHome`         | `cacheHomeAsync`      |
| `stateHome`         | `stateHomeAsync`      |

Use async getters when targeting mobile or when running before the platform context is fully established.

## Helper Methods

| Method                   | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| `ensureDir(path)`        | Creates directory recursively if missing (async)     |
| `ensureDirSync(path)`    | Same, synchronous                                    |
| `dataSubdir(name)`       | Creates `<dataHome>/<name>/`                         |
| `cacheSubdir(name)`      | Creates `<cacheHome>/<name>/`                        |
| `dataSubdirAsync(name)`  | Async version for all platforms                      |
| `cacheSubdirAsync(name)` | Async version for all platforms                      |
| `expandHome(pattern)`    | Expands `~`, `~/`, `$HOME/` to user's home directory |

## Usage in the Codebase

| Consumer                                         | What it stores                                        |
| ------------------------------------------------ | ----------------------------------------------------- |
| `lib/core/config/config_loader.dart`             | Loads `chatorai.json` from `configHomeAsync`          |
| `lib/core/session/database.dart`                 | SQLite database in `dataHomeAsync`                    |
| `lib/core/skills/providers/skill_providers.dart` | Skills directory under `configHome`                   |
| `lib/core/skills/url_source.dart`                | URL-skill cache in `cacheHomeAsync`                   |
| `lib/core/tools/tool_output_persistence.dart`    | Tool output in `dataSubdirAsync('tool-output')`       |
| `lib/core/permission/ruleset.dart`               | Expands `~` in permission patterns via `expandHome()` |
