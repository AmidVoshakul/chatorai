# ChatORAI

A modern AI chat interface with support for multiple models, voice input, and camera functionality.

## 🌟 Features

- **Multiple AI Models** - Support for various models via OpenRouter
- **Voice Input** - Speech-to-text integration
- **Camera & Images** - Take photos and attach to messages
- **Markdown & Code** - Advanced rendering with syntax highlighting
- **Dark/Light Themes** - Adaptive UI with Ubuntu design
- **Multi-language** - RTL support and localization
- **Local Storage** - Chat history and preferences

## 🚀 Quick Start

### 1. Configuration

Create `.env` file in project root:
```env
OPENROUTER_API_KEY=your_api_key_here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

### 2. Development

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build for Linux
flutter build linux
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

## 🔧 Building for Other Platforms

```bash
# Android (with camera support)
flutter build apk --release

# iOS (macOS required)
flutter build ios

# Web
flutter build web
```

## 📋 Dependencies

- `provider` - State management
- `speech_to_text` - Voice input
- `image_picker` - Camera and gallery access
- `permission_handler` - Runtime permissions
- `flutter_markdown_plus` - Markdown rendering
- `dio` - HTTP client
- `shared_preferences` - Local storage
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

## 🐛 Troubleshooting

### Camera not working
```bash
# Check Android permissions
grep CAMERA android/app/src/main/AndroidManifest.xml

# Check iOS permissions
grep NSCameraUsageDescription ios/Runner/Info.plist
```

### Menu launch issues
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

## 📄 License

MIT License