#!/bin/bash

# Run script for Fedora GUI container with Wayland support
# This script runs the fedora_gui container with Wayland support

echo "Starting Fedora GUI container with Wayland support..."

# Check if we're on Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WSL_DISTRO_NAME" ]]; then
    echo "🖥️  Windows Environment Detected"
    echo "❌ Wayland is not supported on Windows"
    echo ""
    echo "📝 Windows uses its own display system (DWM/GDI), not Wayland."
    echo "   Wayland is a Linux-specific display server protocol."
    echo ""
    echo "💡 For GUI applications on Windows, use X11 instead:"
    echo "   ./run-x11.sh $@"
    echo ""
    echo "🔧 If you haven't set up X11 yet:"
    echo "   setup-windows.ps1   # Configure X11 server (PowerShell)"
    echo "   ./run-x11.sh $@     # Run your app (Bash)"
    echo "   # OR"
    echo "   .\\run-x11.ps1 $@   # Run your app (PowerShell)"
    echo ""
    exit 1
fi

# Check if we're on macOS  
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS Detected"
    echo "❌ Wayland is not supported on macOS"
    echo ""
    echo "📝 macOS uses its own display system (Quartz Compositor), not Wayland."
    echo "   Wayland is a Linux-specific display server protocol."
    echo ""
    echo "💡 For GUI applications on macOS, use X11 instead:"
    echo "   ./run-x11.sh $@"
    echo ""
    echo "🔧 If you haven't set up X11 yet:"
    echo "   ./setup-macos.sh    # Configure XQuartz"
    echo "   ./run-x11.sh $@     # Run your app"
    echo ""
    exit 1
fi

# Check if XDG_RUNTIME_DIR is set (Linux)
if [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "🐧 Linux system detected"
    echo "❌ XDG_RUNTIME_DIR environment variable is not set"
    echo "This is required for Wayland support"
    echo ""
    echo "💡 Make sure you're running in a Wayland session:"
    echo "   - GNOME on Wayland"
    echo "   - Sway"
    echo "   - KDE Plasma on Wayland"
    echo "   - Other Wayland compositor"
    echo ""
    echo "🔧 To check your current session:"
    echo "   echo \$XDG_SESSION_TYPE    # Should show 'wayland'"
    echo "   echo \$WAYLAND_DISPLAY     # Should show 'wayland-0' or similar"
    exit 1
fi

# Check if Wayland socket exists
if [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
    echo "🐧 Linux system with XDG_RUNTIME_DIR set"
    echo "❌ Wayland socket not found at $XDG_RUNTIME_DIR/wayland-0"
    echo ""
    echo "🔍 Checking for other Wayland sockets..."
    WAYLAND_SOCKETS=$(find "$XDG_RUNTIME_DIR" -name "wayland-*" -type s 2>/dev/null)
    if [ -n "$WAYLAND_SOCKETS" ]; then
        echo "🔌 Found Wayland sockets:"
        echo "$WAYLAND_SOCKETS"
        echo ""
        echo "💡 You may need to set WAYLAND_DISPLAY to match your socket"
    else
        echo "❌ No Wayland sockets found in $XDG_RUNTIME_DIR"
    fi
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   - Make sure you're running under Wayland (not X11)"
    echo "   - Check: echo \$XDG_SESSION_TYPE"
    echo "   - Try logging out and selecting a Wayland session"
    echo "   - For X11 sessions, use: ./run-x11.sh $@"
    exit 1
fi

echo "✅ Wayland environment detected and ready"

# Default command is gedit if no arguments provided
if [ $# -eq 0 ]; then
    set -- "gedit"
fi

echo "Running: podman run --rm -it --security-opt label=disable -v $XDG_RUNTIME_DIR/wayland-0:/run/user/1000/wayland-0 -e WAYLAND_DISPLAY=wayland-0 fedora_gui $@"

# Run the container with Wayland support
podman run --rm -it \
    --security-opt label=disable \
    -v "$XDG_RUNTIME_DIR/wayland-0:/run/user/1000/wayland-0" \
    -e WAYLAND_DISPLAY=wayland-0 \
    fedora_gui "$@"
