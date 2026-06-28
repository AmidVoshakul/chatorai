# Windows Development Setup Guide

This guide will help you set up ChatORAI for development and testing on Windows.

## Prerequisites

### 1. Install Flutter SDK

**Option A: Using Chocolatey (Recommended)**
```powershell
choco install flutter
```

**Option B: Manual Installation**
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to `C:\src\flutter`
3. Add to PATH:
   - Open System Properties → Environment Variables
   - Add `C:\src\flutter\bin` to PATH

### 2. Install Visual Studio

Download and install [Visual Studio 2022 Community](https://visualstudio.microsoft.com/downloads/):

- Select **"Desktop development with C++"** workload
- Include **Windows 10/11 SDK**
- Include **C++ CMake tools** (required by `sqlite3_flutter_libs` / Drift for native SQLite compilation)

### 3. Verify Installation

Open PowerShell and run:
```powershell
flutter doctor
```

You should see:
```
✓ Flutter
✓ Android toolchain (if needed)
✓ Visual Studio (for Windows development)
✓ Chrome (for web)
```

## Building and Running

### Quick Start

```powershell
# Clone or navigate to project
cd "C:\path\to\chatorai"

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Build release version
flutter build windows --release
```

### Build Locations

- **Debug**: `build\windows\runner\Debug\chatorai.exe`
- **Release**: `build\windows\runner\Release\chatorai.exe`

## Testing File Upload on Windows

### Step 1: Build and Run
```powershell
# Build release version
flutter build windows --release

# Run the built version
.\build\windows\runner\Release\chatorai.exe
```

### Step 2: Test File Upload
1. Click the 📎 (plus) button
2. Select "File" or "Image"
3. The Windows file picker should open
4. Select any file
5. File should attach without permission errors

### Step 3: Verify Desktop Platform Handling
The app should:
- ✅ Skip permission requests (no permission_handler calls)
- ✅ Open Windows file picker
- ✅ Handle file selection correctly
- ✅ Show file name and type
- ✅ Allow sending with file

## Common Issues and Solutions

### Issue: "Flutter is not recognized"

**Solution**: Add Flutter to PATH
```powershell
# In PowerShell as Administrator
[Environment]::SetEnvironmentVariable(
    "Path", 
    [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\src\flutter\bin",
    "Machine"
)
```

### Issue: Build fails with CMake errors

**Solution**: Install Visual Studio C++ workload
```powershell
# Open Visual Studio Installer
# Modify → Desktop development with C++
# Ensure Windows SDK is selected
```

### Issue: File picker doesn't open

**Solution**: Check Windows file associations
```powershell
# Reset file associations
Start-Process "ms-settings:defaultapps" -Wait
```

### Issue: App crashes on startup

**Solution**: Install Visual C++ Redistributable
```powershell
# Download and install
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "vc_redist.exe"
.\vc_redist.exe /install /quiet /norestart
```

## Development Workflow

### 1. Make Changes
Edit files in `lib/` directory

### 2. Hot Reload
While app is running:
- Press `r` in terminal to hot reload
- Press `R` to hot restart

### 3. Build for Testing
```powershell
# Release build for testing
flutter build windows --release

# Run the built executable
.\build\windows\runner\Release\chatorai.exe
```

### 4. Debug Build
```powershell
# Debug build with symbols
flutter build windows --debug

# Run with debugger
flutter run -d windows --debug
```

## Testing Checklist

Use this checklist to verify all functionality:

- [ ] **File Upload**: 📎 → File → Select file → Attach
- [ ] **Image Upload**: 📎 → Image → Select image → Attach
- [ ] **Camera**: 📎 → Camera (should not appear on Windows)
- [ ] **Model Support Check**: Warning shows for unsupported models
- [ ] **Data Preservation**: Text kept when model doesn't support files
- [ ] **Multiple Files**: Can attach multiple files
- [ ] **File Types**: Test different file types (PDF, TXT, images)
- [ ] **Send with File**: Message sends with file attachment
- [ ] **Cancel**: Can cancel file selection
- [ ] **Clear**: Can remove attached file

## Performance Testing

### Memory Usage
```powershell
# Monitor memory while using app
Get-Process chatorai | Select-Object WS
```

### File Size Limits
Test with large files:
- Small: < 1MB
- Medium: 1-10MB
- Large: 10-50MB
- Very Large: > 50MB

## Debugging

### Enable Verbose Logging
```powershell
flutter run -d windows --verbose
```

### View Logs
```powershell
# In PowerShell
flutter logs
```

### Debug in VS Code
1. Open project in VS Code
2. Install Flutter extension
3. Press F5 or click "Run → Start Debugging"
4. Select "Windows (desktop)"

## Distribution

### Create Installer
Use tools like:
- **Inno Setup**: Free, script-based
- **NSIS**: Free, powerful
- **WiX Toolset**: Microsoft, XML-based

### Code Signing (Optional)
```powershell
# Sign executable
signtool sign /f "certificate.pfx" /p "password" /tr http://timestamp.digicert.com /td sha256 /fd sha256 "chatorai.exe"
```

## Additional Resources

- [Flutter Windows Setup](https://flutter.dev/docs/get-started/install/windows)
- [Flutter Desktop Documentation](https://flutter.dev/docs/desktop)
- [Windows App Distribution](https://flutter.dev/docs/deployment/windows)

## Support

If you encounter issues:
1. Check `flutter doctor` output
2. Verify Visual Studio installation
3. Check Windows Event Viewer for errors
4. Review Windows Troubleshooting section in README.md