#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# ChatORAI one-command installer (end users, no Flutter required)
#
# Downloads a prebuilt Linux bundle from GitHub Releases and installs it to
# /usr/local/lib/chatorai with a desktop entry and a `chatorai` launcher that
# transparently falls back to software OpenGL on old GPUs.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | sudo bash
#   sudo ./install_chatorai.sh                 # latest stable release
#   sudo ./install_chatorai.sh --version 0.1.0 # specific version
#   sudo ./install_chatorai.sh --help
# -----------------------------------------------------------------------------

REPO="AmidVoshakul/chatorai"

RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
ChatORAI Installer

Usage: install_chatorai.sh [options]

Options:
  -h, --help               Show this help message
  -v, --version <version>  Install a specific version (e.g. 0.1.0 or v0.1.0)
EOF
}

# ---------------------------------------------------------
# Argument parsing (opencode-style)
# ---------------------------------------------------------
VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            if [[ -n "${2:-}" ]]; then
                VERSION="$2"
                shift 2
            else
                echo -e "${RED}Error: --version requires a value${NC}"
                exit 1
            fi
            ;;
        *)
            echo "Warning: unknown option '$1'" >&2
            shift
            ;;
    esac
done

echo "Installing ChatORAI..."

# Require sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# ---------------------------------------------------------
# 1. Detect architecture
# ---------------------------------------------------------
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_TRIPLE="x64" ;;
    aarch64 | arm64) ARCH_TRIPLE="arm64" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

# ---------------------------------------------------------
# 2. Resolve version / download URL
# ---------------------------------------------------------
if [ -z "$VERSION" ]; then
    echo "Resolving latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -z "$VERSION" ]; then
    echo -e "${RED}Could not determine latest version.${NC}"
    echo "   Try: sudo ./install_chatorai.sh --version v0.1.0"
    echo "   Releases: https://github.com/$REPO/releases"
    exit 1
fi

# Normalize to a tag (assets are published under vX.Y.Z).
case "$VERSION" in
    v*) VERSION_TAG="$VERSION" ;;
    *)  VERSION_TAG="v$VERSION" ;;
esac

echo "Installing ChatORAI $VERSION_TAG for linux-$ARCH_TRIPLE..."

URL="https://github.com/$REPO/releases/download/${VERSION_TAG}/chatorai-linux-${ARCH_TRIPLE}-${VERSION_TAG}.tar.gz"
TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
cd "$TMPDIR"

# ---------------------------------------------------------
# 3. Download + extract
# ---------------------------------------------------------
echo "Downloading $URL ..."
if ! curl -fL -o bundle.tar.gz "$URL"; then
    echo -e "${RED}Download failed. Check the version and your connection.${NC}"
    echo "   Available releases: https://github.com/$REPO/releases"
    exit 1
fi

echo "Extracting..."
mkdir -p bundle
tar -xzf bundle.tar.gz -C bundle

# The tarball may contain the bundle contents directly or under a subdir.
# Find the directory that holds the `chatorai` executable (expect exactly one).
mapfile -t BIN_MATCHES < <(find bundle -type f -name chatorai 2>/dev/null)
if [ "${#BIN_MATCHES[@]}" -ne 1 ]; then
    echo -e "${RED}Expected exactly one 'chatorai' binary in the archive, found ${#BIN_MATCHES[@]}.${NC}"
    exit 1
fi
BUNDLE_ROOT="$(dirname "${BIN_MATCHES[0]}")"
if [ ! -f "$BUNDLE_ROOT/chatorai" ]; then
    echo -e "${RED}Could not locate the ChatORAI executable in the archive.${NC}"
    exit 1
fi

# ---------------------------------------------------------
# 4. Install files
# ---------------------------------------------------------
echo "Installing files..."
install -d /usr/local/lib/chatorai
install -d /usr/local/bin
rm -rf /usr/local/lib/chatorai/*
cp -r "$BUNDLE_ROOT"/* /usr/local/lib/chatorai/

# ---------------------------------------------------------
# 5. Install icon
# ---------------------------------------------------------
echo "Installing icon..."
ICON_DST="/usr/share/icons/hicolor/256x256/apps/chatorai.png"
mkdir -p "$(dirname "$ICON_DST")"

# The real icon ships inside the Flutter asset bundle.
ICON_SRC=$(find /usr/local/lib/chatorai/data/flutter_assets/assets \
    -maxdepth 1 -type f -name 'chatorai_logo*.png' 2>/dev/null | head -1 || true)
if [ -z "$ICON_SRC" ]; then
    ICON_SRC=$(find /usr/local/lib/chatorai -maxdepth 2 -type f -name '*.png' 2>/dev/null | head -1 || true)
fi

if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
    if command -v convert >/dev/null 2>&1; then
        convert "$ICON_SRC" -resize 256x256 "$ICON_DST" || cp "$ICON_SRC" "$ICON_DST"
    else
        cp "$ICON_SRC" "$ICON_DST"
    fi
else
    echo "⚠️ Icon not found, creating placeholder"
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$ICON_DST"
fi

# ---------------------------------------------------------
# 6. OpenGL compatibility (install-time hint)
# ---------------------------------------------------------
# Flutter/GTK on Linux needs OpenGL >= 3.0. Some old GPUs (e.g. Intel HD
# "ILK"/Ironlake) only expose OpenGL 2.1 and segfault under hardware GL, so we
# must run under software rendering (llvmpipe) instead.
#
# We do NOT launch the GUI here (no reliable display session under sudo, and it
# is the source of subtle failures). Instead we read the reported GL version
# via glxinfo as a safe, non-crashing hint, and drop a flag file. The runtime
# launcher additionally self-heals if this guess is wrong.
echo "Checking OpenGL compatibility..."
USE_SOFT_GL=0
if command -v glxinfo >/dev/null 2>&1; then
    # Run glxinfo as the invoking user so it sees their GPU/driver, not root's.
    RUN_USER="${SUDO_USER:-$USER}"
    if [ -n "${SUDO_USER:-}" ]; then
        GLX_OUT="$(sudo -u "$RUN_USER" glxinfo 2>/dev/null || true)"
    else
        GLX_OUT="$(glxinfo 2>/dev/null || true)"
    fi

    GL_VERSION_LINE="$(echo "$GLX_OUT" | grep -m1 -i 'OpenGL version string' || true)"
    # Extract the leading "major.minor" number, e.g. "2.1", "4.6".
    GL_MAJOR="$(echo "$GL_VERSION_LINE" | sed -n 's/^[^:]*: *\([0-9]\+\)\..*/\1/p')"

    if [ -z "$GLX_OUT" ] \
       || echo "$GLX_OUT" | grep -qiE 'renderer string:.*(llvmpipe|softpipe|swrast)'; then
        USE_SOFT_GL=1
    elif [ -n "$GL_MAJOR" ] && [ "$GL_MAJOR" -lt 3 ]; then
        echo "   Detected OpenGL < 3.0 (${GL_MAJOR}.x) — enabling software rendering"
        USE_SOFT_GL=1
    fi
else
    echo "   glxinfo not available; the launcher will auto-detect at runtime"
fi

if [ "$USE_SOFT_GL" -eq 1 ]; then
    touch /usr/local/lib/chatorai/.force_soft_gl
    echo "   Software rendering enabled. To force hardware GL later:"
    echo "     sudo rm /usr/local/lib/chatorai/.force_soft_gl"
else
    rm -f /usr/local/lib/chatorai/.force_soft_gl
fi

# ---------------------------------------------------------
# 7. Create launcher (self-healing OpenGL)
# ---------------------------------------------------------
echo "Creating launcher..."
cat > /usr/local/bin/chatorai << 'EOF'
#!/bin/bash
INSTALL_DIR="/usr/local/lib/chatorai"

# Explicit override always wins.
if [ "$CHATORAI_FORCE_SOFT_GL" = "1" ] || [ -f "$INSTALL_DIR/.force_soft_gl" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    exec "$INSTALL_DIR/chatorai" "$@"
fi
if [ "$CHATORAI_FORCE_SOFT_GL" = "0" ]; then
    exec "$INSTALL_DIR/chatorai" "$@"
fi

# Proactively check the OpenGL version once and cache the decision: GPUs
# exposing OpenGL < 3.0 will crash under hardware GL, so switch to software
# rendering before the first launch (no crash needed).
if command -v glxinfo >/dev/null 2>&1; then
    GLV="$(glxinfo 2>/dev/null | grep -m1 -i 'OpenGL version string' \
        | sed -n 's/^[^:]*: *\([0-9]\+\)\..*/\1/p')"
    if [ -n "$GLV" ] && [ "$GLV" -lt 3 ]; then
        touch "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
        export LIBGL_ALWAYS_SOFTWARE=1
        export GALLIUM_DRIVER=llvmpipe
        exec "$INSTALL_DIR/chatorai" "$@"
    fi
fi

# Otherwise try hardware GL. If the GUI dies from a GL-related crash
# (SIGSEGV=139 / SIGABRT=134), transparently retry with software rendering and
# remember it. Only auto-retry the GUI (no CLI args) so CLI exit codes survive.
"$INSTALL_DIR/chatorai" "$@"
RC=$?
if { [ "$RC" = "139" ] || [ "$RC" = "134" ]; } && [ "$#" -eq 0 ]; then
    echo "chatorai: hardware OpenGL crashed (exit $RC); retrying with software rendering" >&2
    touch "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    exec "$INSTALL_DIR/chatorai" "$@"
fi
exit $RC
EOF
chmod +x /usr/local/bin/chatorai

# ---------------------------------------------------------
# 8. Desktop entry
# ---------------------------------------------------------
echo "Creating desktop entry..."
cat > /usr/share/applications/chatorai.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ChatORAI
Comment=AI Chat Application
Exec=/usr/local/bin/chatorai
Icon=chatorai
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;OpenRouter;
StartupNotify=true
EOF

# ---------------------------------------------------------
# 9. Update caches
# ---------------------------------------------------------
echo "Updating caches..."
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "Run:            chatorai"
echo "Update later:   chatorai upgrade"
echo "Uninstall:      sudo rm -rf /usr/local/lib/chatorai \\"
echo "                  /usr/local/bin/chatorai \\"
echo "                  /usr/share/applications/chatorai.desktop \\"
echo "                  /usr/share/icons/hicolor/256x256/apps/chatorai.png"
echo ""
