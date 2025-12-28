#!/bin/bash

# Installation script for ChatORAI
set -e

echo "Installing ChatORAI..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# Build the application first
echo "Step 1: Building application..."
cd "$(dirname "$0")"
export PATH="/opt/flutter/bin:$PATH"
flutter build linux --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Create directories
echo "Step 2: Creating directories..."
mkdir -p /usr/local/lib/chatorai
mkdir -p /usr/local/bin

# Copy application files
echo "Step 3: Copying files..."
cp -r build/linux/x64/release/bundle/* /usr/local/lib/chatorai/

# Copy icon if exists
echo "Step 3b: Copying icon..."
if [ -f "assets/chatorai_logo.png" ]; then
    cp assets/chatorai_logo.png /usr/local/lib/chatorai/chatorai.png
    echo "✅ Custom icon copied"
else
    echo "⚠️  Custom icon not found, using default"
fi

# Also copy to system icons
if [ -f "assets/chatorai_logo.png" ]; then
    # Convert to proper format if ImageMagick available
    if command -v convert &> /dev/null; then
        convert assets/chatorai_logo.png -resize 256x256 /usr/share/icons/hicolor/256x256/apps/chatorai.png 2>/dev/null || cp assets/chatorai_logo.png /usr/share/icons/hicolor/256x256/apps/chatorai.png
    else
        cp assets/chatorai_logo.png /usr/share/icons/hicolor/256x256/apps/chatorai.png
    fi
fi

# Create wrapper script
echo "Step 4: Creating launcher..."
cat > /usr/local/bin/chatorai << 'EOF'
#!/bin/bash
export PATH="/opt/flutter/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib/chatorai/lib:$LD_LIBRARY_PATH"
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$(whoami)}
export HOME=${HOME:-/home/$(whoami)}
export USER=${USER:-$(whoami)}

# Fix for OpenGL issues
export MESA_GL_VERSION_OVERRIDE=3.3
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

cd /usr/local/lib/chatorai
exec ./chatorai "$@"
EOF

chmod +x /usr/local/bin/chatorai

# Create desktop launcher
cat > /usr/local/lib/chatorai/chatorai-launcher << 'EOF'
#!/bin/bash
export PATH="/opt/flutter/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib/chatorai/lib:$LD_LIBRARY_PATH"
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$(whoami)}
export HOME=${HOME:-/home/$(whoami)}
export USER=${USER:-$(whoami)}

export MESA_GL_VERSION_OVERRIDE=3.3
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

cd /usr/local/lib/chatorai
exec ./chatorai
EOF

chmod +x /usr/local/lib/chatorai/chatorai-launcher

# Create desktop file
echo "Step 5: Creating desktop entry..."
cat > /usr/share/applications/chatorai.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ChatORAI
Comment=AI Chat Application
Exec=/usr/local/lib/chatorai/chatorai-launcher
Icon=/usr/share/icons/hicolor/256x256/apps/chatorai.png
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;OpenRouter;
StartupNotify=true
EOF

# Install icon
echo "Step 6: Installing icon..."
if [ -f "assets/chatorai_logo.png" ]; then
    # Create icons directory if needed
    mkdir -p /usr/share/icons/hicolor/256x256/apps/
    
    # Copy and resize if possible
    if command -v convert &> /dev/null; then
        convert assets/chatorai_logo.png -resize 256x256 /usr/share/icons/hicolor/256x256/apps/chatorai.png 2>/dev/null || cp assets/chatorai_logo.png /usr/share/icons/hicolor/256x256/apps/chatorai.png
    else
        cp assets/chatorai_logo.png /usr/share/icons/hicolor/256x256/apps/chatorai.png
    fi
    echo "✅ Icon installed"
else
    # Create placeholder icon
    echo "⚠️  Creating placeholder icon"
    mkdir -p /usr/share/icons/hicolor/256x256/apps/
    echo "AI" > /usr/share/icons/hicolor/256x256/apps/chatorai.png
fi

# Update databases
echo "Step 7: Updating system databases..."
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "You can now:"
echo "  - Run from terminal: chatorai"
echo "  - Find in applications menu: 'ChatORAI'"
echo "  - Or run: /usr/local/lib/chatorai/chatorai"
echo ""
echo "To uninstall:"
echo "  sudo rm -rf /usr/local/lib/chatorai"
echo "  sudo rm /usr/local/bin/chatorai"
echo "  sudo rm /usr/share/applications/chatorai.desktop"
echo "  sudo rm /usr/share/icons/hicolor/256x256/apps/chatorai.png"