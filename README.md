# ChatORAI

![Screenshot of ChatORAI interface](https://github.com/AmidVoshakul/chatorai/blob/main/screenshots/Screenshot_2025-12-30_01-04-32.png)

A multi-provider AI chat interface built on Flutter and Riverpod 3.x. Supports any OpenAI-compatible API (OpenRouter, local models, custom endpoints) via `ai_sdk_dart` v1.1.0.

**🇷🇺 Русская версия**: [README_RU.md](README_RU.md)

## 🌟 Features

- **Multiple AI Models** - Support for various models via OpenRouter
- **Voice Input** - Speech-to-text integration
- **Camera & Images** - Take photos and attach to messages
- **Markdown & Code** - Advanced rendering with syntax highlighting
- **Dark/Light Themes** - Adaptive UI with Ubuntu design
- **Multi-language** - RTL support and localization
- **Local Storage** - Chat history and preferences

## 🚀 Quick Start

### Prerequisites

- Flutter 3.41.0 (stable)
- Dart SDK 3.11.0+
- For Linux runtime: `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`

### 1. Configuration

**Development** — copy `.env.example` to `.env` and add your API key:
```env
OPENROUTER_API_KEY=your_api_key_here
```
`.env` is gitignored and **not bundled into release builds**.

**Release / runtime** — users paste the API key and base URL in-app settings. Values are stored in `SharedPreferences`.

### 2. Fetch & Generate

```bash
flutter pub get
# After editing any file under lib/l10n/*.arb only:
flutter gen-l10n
```

### 3. Verify

```bash
flutter analyze
flutter test
```

### 4. Run

```bash
flutter run -d linux
flutter run -d windows
flutter run -d chrome
flutter run -d android
# iOS requires macOS
flutter run -d ios
```

## 📦 Linux Installation

### Automatic (Recommended)

```bash
sudo ./install_app.sh
```

This installs:
- App to `/usr/local/lib/chatorai/`
- Desktop entry and icon
- `chatorai` command

### Manual

```bash
sudo cp -r build/linux/x64/release/bundle/* /usr/local/lib/chatorai/
sudo ln -sf /usr/local/lib/chatorai/chatorai /usr/local/bin/chatorai
```

### Run After Install

- **Menu**: Find "ChatORAI"
- **Terminal**: `chatorai`

### Uninstall

```bash
sudo rm -rf /usr/local/lib/chatorai
sudo rm /usr/local/bin/chatorai
sudo rm /usr/share/applications/chatorai.desktop
sudo rm /usr/share/icons/hicolor/256x256/apps/chatorai.png
```

## 🪟 Windows Installation

### Automatic (Recommended)

1. **Build the application**:
```bash
flutter build windows --release
```

2. **Run the installer**:
   - **PowerShell** (recommended):
     ```powershell
     # Run as Administrator
     PowerShell -ExecutionPolicy Bypass -File ".\install_app.ps1"
     ```
   - **Command Prompt**:
     ```cmd
     # Run as Administrator
     install_app.bat
     ```

The installer will:
- Copy files to `C:\Program Files\ChatORAI\`
- Create Start Menu shortcut
- Optionally add to PATH
- Create uninstaller

### Manual Installation

1. **Build the app**:
```bash
flutter build windows --release
```

2. **Copy files**:
   - Navigate to `build\windows\runner\Release\`
   - Copy all files to your desired location (e.g., `C:\Program Files\ChatORAI\`)

3. **Create shortcut**:
   - Right-click `chatorai.exe`
   - Send to → Desktop (create shortcut)
   - Or pin to Start Menu

### Run After Install

- **Start Menu**: Search for "ChatORAI"
- **Desktop**: Double-click the shortcut
- **Command Prompt**: `C:\Program Files\ChatORAI\chatorai.exe`

### Uninstall

1. **Delete installation folder**:
```powershell
Remove-Item -Path "C:\Program Files\ChatORAI" -Recurse -Force
```

2. **Delete shortcuts**:
```powershell
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk" -Force
Remove-Item -Path "$env:USERPROFILE\Desktop\ChatORAI.lnk" -Force
```

### Requirements for Building on Windows

- **Flutter SDK** installed and in PATH
- **Visual Studio 2019 or later** with:
  - Desktop development with C++
  - Windows 10/11 SDK
- **Git** for dependency management

**Detailed setup guide**: See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for complete development setup instructions.

### Windows Troubleshooting

**Missing DLL errors**:
- Install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
- Or build in Release mode: `flutter build windows --release`

**Firewall warnings**:
- The app needs internet access for API calls
- Allow through Windows Defender Firewall if prompted

**Path too long errors**:
- Move project to shorter path: `C:\dev\chatorai\`
- Or use: `flutter build windows --release --verbose`

## 🔧 Building for Other Platforms

```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Android (with camera support)
flutter build apk --release

# iOS (macOS required)
flutter build ios

# Web
flutter build web
```

### Quick Build Commands

**Windows (PowerShell)**:
```powershell
# Build
flutter build windows --release

# Run directly
flutter run -d windows

# Run in debug mode
flutter run -d windows --debug
```

**Linux/Windows (Terminal)**:
```bash
# Build release
flutter build windows --release  # Windows
flutter build linux --release    # Linux

# Run directly
flutter run -d windows          # Windows
flutter run -d linux            # Linux
```

## 📦 Supported File Types

### Images
- PNG, JPG, JPEG, GIF, WebP, HEIC, SVG

### Text Files
- TXT, MD, RTF, CSV, HTML, XML, JSON, YAML

### Documents
- PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX

### Archives
- ZIP, RAR, 7Z, TAR, GZ

### Code Files
- Dart, JavaScript, TypeScript, Python, Java, C/C++, C#, Go, Rust, PHP, Ruby, Swift

### Audio
- MP3, WAV, OGG, M4A

### Video
- MP4, AVI, MOV, MKV, WebM

## 📤 File Upload Workflow

### Step 1: Check Model Support
When you click the 📎 button:
- App checks if current model supports files
- Shows warning if not supported
- **Still allows file selection** (you can type text first)

### Step 2: Select File
- **Desktop/Mobile**: Native file picker opens
- **Web**: Browser file picker opens
- **Camera**: Camera app opens (mobile only)

### Step 3: Attach & Review
- File is attached to message
- File name and type displayed
- You can continue typing

### Step 4: Send Message
- App checks model support again
- If unsupported: Shows error, **keeps your data**
- If supported: Sends message with file

### Data Loss Prevention
```
❌ Old behavior: Model doesn't support files → Clear everything
✅ New behavior: Model doesn't support files → Show error, keep text + file
```

You can then:
- Switch to a model that supports files
- Remove the file and send text only
- Try again with different model

## 📋 Dependencies

- `flutter_riverpod` - State management (Riverpod 3.x)
- `speech_to_text` - Voice input
- `image_picker` - Camera and gallery access
- `file_picker` - File selection
- `permission_handler` - Runtime permissions
- `flutter_markdown_plus` - Markdown rendering
- `flutter_highlight` - Code syntax highlighting
- `markdown` - Markdown parsing
- `dio` - HTTP client
- `shared_preferences` - Local storage
- `connectivity_plus` - Network status monitoring
- `logger` - Logging
- `flutter_dotenv` - Environment variables
- `path_provider` - File system paths
- `package_info_plus` - App version info
- `flutter_launcher_icons` - Icon generation

## 🛠️ Development

```bash
# Tests
flutter test

# Hot reload
flutter run --hot-reload

# Analyze
flutter analyze

# Generate icons
flutter pub run flutter_launcher_icons:main
```

## 🏗️ Architecture

### AI Layer

- `ai_sdk_dart` v1.1.0 — streaming (`streamText`) and non-streaming (`generateText`) completions
- `ai_sdk_openai` — `OpenAIProvider` adapter, pointed at any OpenAI-compatible base URL
- `ai_sdk_provider` — shared provider utilities

### Multi-Provider Model

Models are identified as `provider/model_id` (e.g. `openrouter/anthropic/claude-sonnet-4`). The app stores a base URL + model ID pair, so it works with OpenRouter, local LLM servers, or any OpenAI-compatible endpoint.

### State Management

Riverpod 3.x providers in `lib/providers/` (barrel via `lib/providers.dart`).

### Data Flow

```
UI → providers → ChatAiService → streamText() / generateText() → OpenAIProvider → API
Models  → Dio → OpenRouter /models endpoint → OpenRouterModel
Config → SharedPreferences (runtime API key, baseUrl, model settings)
```

## ⚠️ Known Gotchas

- `.env` is **dev-only**. It is not bundled in release builds. Runtime users enter credentials in settings.
- `integration_test/` directory has been removed. The standalone script at `integration_test/api_test.dart` runs via `dart integration_test/api_test.dart` (requires `.env`), NOT `flutter test integration_test/`.
- `analysis_options.yaml` excludes `test/**` from the analyzer. `flutter analyze` passing does not guarantee tests are lint-clean.
- Linux desktop requires system libraries: `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`.
- Windows desktop requires Visual C++ workload + Windows 10/11 SDK.

## 🐛 Troubleshooting

### Camera not working
```bash
# Check Android permissions
grep CAMERA android/app/src/main/AndroidManifest.xml

# Check iOS permissions
grep NSCameraUsageDescription ios/Runner/Info.plist
```

### Menu launch issues (Linux)
```bash
# Test terminal launch
chatorai

# Check installation
ls -la /usr/local/lib/chatorai/
```

### Missing dependencies (Ubuntu/Debian)
```bash
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2
```

### Windows-specific Issues

**"The code execution cannot proceed because..." errors**:
```powershell
# Install Visual C++ Redistributable
# Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
```

**"Flutter is not recognized as an internal or external command"**:
```powershell
# Add Flutter to PATH
# System Properties → Environment Variables → Path → Add Flutter bin directory
```

**Windows Defender SmartScreen blocks app**:
- Click "More info" → "Run anyway"
- Or sign the executable with a code signing certificate

**File picker doesn't open**:
- Check Windows file associations
- Run as Administrator once to test
- Check Windows Event Viewer for errors

**Build fails with "CMake not found"**:
- Install Visual Studio with C++ workload
- Or install CMake manually: https://cmake.org/download/

## 📄 License

MIT License
