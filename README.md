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

- `provider` - State management
- `speech_to_text` - Voice input
- `image_picker` - Camera and gallery access
- `file_picker` - File selection
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