# Environment & System Requirements

**Last updated:** 2026-06-12

This document describes the software and hardware requirements, environment variables, and system dependencies needed to develop, build, and run ChatORAI.

---

## Development Environment

### Required Software

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | 3.41.0 (stable) | Download from https://flutter.dev |
| Dart SDK | 3.9 (bundled with Flutter) | |
| Git | 2.x | For dependency management and version control |
| IDE | VS Code / Android Studio / IntelliJ | With Flutter & Dart plugins |

### OS-specific Requirements

#### Linux (Debian/Ubuntu)

Install system libraries:

```bash
sudo apt update
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2
```

For audio/video support (optional):

```bash
sudo apt install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good
```

#### Windows

- **Visual Studio 2019 or later** with:
  - Desktop development with C++
  - Windows 10/11 SDK
- **CMake** (if not included with Visual Studio)
- **PowerShell 5.x or later** (for install scripts)

If you encounter "CMake not found" errors, install CMake from https://cmake.org/download/ or via Visual Studio installer.

#### macOS

- Xcode 15+ (for iOS builds)
- CocoaPods (usually installed with Xcode Command Line Tools)
- macOS is required to build iOS apps; Linux/Windows cannot build for iOS.

---

## Runtime Dependencies

When running from source or after installation:

- **Internet access** — for API calls to OpenRouter or custom endpoints.
- **Microphone** — for voice input (optional, requires `permission_handler` on mobile).
- **Camera** — for image capture (mobile only, requires permissions).

---

## Environment Variables

ChatORAI uses two sources of configuration:

### 1. `.env` (Development Only)

Located in project root. **Ignored by git** (`.gitignore`). Not bundled in release builds.

```env
# Required for development: Your OpenRouter API key
OPENROUTER_API_KEY=sk-or-v1-...

# Optional overrides
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
CHATORAI_DEBUG=true
```

**Important:** Release builds do not read `.env`. End-users enter credentials via in-app settings, stored in `SharedPreferences`.

### 2. `SharedPreferences` (Runtime)

At first launch, the user can input:
- API key (stored securely; not logged)
- Base URL (default: OpenRouter)
- Model settings (temperature, maxTokens)

Values are persisted per-platform:
- Linux/Windows: registry or JSON file under app data directory
- Android/iOS: secure shared preferences
- Web: localStorage

---

## Configuration File: chatorai.json

Optional user-editable JSON configuration. Searched in order:

1. `~/.config/chatorai/chatorai.json` (cross-platform user config dir)
2. `<project>/.chatorai/chatorai.json` (project-local)

**Schema** (`lib/core/config/chatorai_schema.dart`) with `$schema` URL for IDE autocomplete:

```json5
{
  "version": 1,
  "permission": {
    "default": "ask",
    "rules": [
      { "tool": "read", "action": "*", "resource": "*", "permission": "allow" },
      { "tool": "bash", "action": "execute", "resource": "/home/**", "permission": "deny" }
    ]
  },
  "provider": { /* multi-provider registry configuration (implemented) */ },
  "keybinding": {
    // Reserved for future keybinds system (not yet implemented)
    "leader": "ctrl+x",
    "timeout": 2000,
    "bindings": { "session_child_next": "ctrl+right" },
    "quick_commands": { /* @ triggers implemented; # and / planned */ }
  }
}
```

**Validation:** Startup fails with user-friendly error if JSON is invalid or mismatches schema.

---

## Build Configuration

### analysis_options.yaml

- Uses `package:lints/recommended.yaml` as base.
- Excludes `test/**` from analyzer to avoid false positives in test mocks.
- Zero warnings required before commit (`flutter analyze` must pass clean).

### pubspec.yaml

Key dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.2.1
  ai_sdk_dart: ^1.1.0
  ai_sdk_openai: ^1.1.0
  dio: ^5.8.2+1
  shared_preferences: ^2.3.4
  flutter_markdown_plus: ^2.0.0
  # ... (see full pubspec.yaml)

dev_dependencies:
  flutter_test:
  flutter_lints: ^4.0.0
  build_runner: ^2.4.15
```

---

## Platform Build Notes

### Linux

- **Software rendering** (for headless CI or GPU issues):
  ```bash
  LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux
  ```
- **Installation script**: `install_app.sh` copies bundle to `/usr/local/lib/chatorai/` and creates `chatorai` CLI command.

### Windows

- **Build**:
  ```powershell
  flutter build windows --release
  ```
- **Installer**: `install_app.ps1` (PowerShell) or `install_app.bat` (CMD). Run as Administrator.
- **Runtime DLLs**: If you see missing DLL errors, install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe).

### Android

- Ensure `android/app/src/main/AndroidManifest.xml` declares required permissions (camera, microphone, storage).
- Build APK (or AAB):
  ```bash
  flutter build apk --release
  flutter build appbundle --release  # for Google Play
  ```

### iOS

- Requires macOS with Xcode.
- `ios/Runner/Info.plist` must include `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`.
- Build:
  ```bash
  flutter build ios --release
  ```

---

## Network & Security

- **TLS**: All external API calls must use HTTPS. Dio validates certificates by default.
- **No secrets in logs**: Sensitive data (API keys, tokens) are filtered from log output.
- **Rate limiting**: Client-side backoff respects server `Retry-After` headers to avoid throttling.
- **Sanitization**: User-facing error messages are truncated; stack traces omitted.

---

## Troubleshooting

### Flutter doctor reports issues

```bash
flutter doctor --verbose
```

Fix missing components according to the output (Android SDK, Xcode, etc.).

### Dependencies not found

```bash
flutter pub get
# If still failing, clear cache:
flutter pub cache repair
```

### Tests fail due to version mismatch

Ensure Flutter SDK is exactly 3.41.0 (check `flutter --version`). Some packages require specific Flutter versions.

### Linux: App fails to start with GTK errors

Reinstall GTK libs:

```bash
sudo apt install --reinstall libgtk-3-0 libgdk-pixbuf2.0-0 libpango-1.0-0 libcairo2
```

### Windows: "CMake not found"

Install CMake via Visual Studio Installer or standalone from https://cmake.org/download/.

### iOS Simulator not found (macOS)

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

---

## Performance Tuning

- **Token budget**: Models have context lengths (e.g., 200k tokens). `OverflowDetector` warns when approaching limits.
- **Auto-scroll**: Disabled when user manually scrolls up >150px; re-enabled when returning near bottom.
- **Streaming throttle**: Updates at 250ms intervals or word boundaries to reduce UI churn.

---

For command reference, see `docs/COMMANDS.md`.  
For API details, see `docs/API.md`.  
For architecture, see `ARCHITECTURE.md`.  
For known issues and workarounds, see `README.md` "Known Gotchas" section.
