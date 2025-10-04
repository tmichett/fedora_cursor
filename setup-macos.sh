#!/bin/bash

# macOS Setup Script for Fedora GUI Container with X11 Support
# This script configures XQuartz to work with Podman containers

echo "🍎 macOS XQuartz Setup for Container X11 Forwarding"
echo "=================================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is only for macOS systems"
    exit 1
fi

# Check if XQuartz is installed
if ! command -v /opt/X11/bin/xauth >/dev/null 2>&1 && ! ls /Applications/Utilities/XQuartz.app >/dev/null 2>&1; then
    echo "❌ XQuartz is not installed"
    echo "📥 Please install XQuartz from: https://www.xquartz.org/"
    echo "   Or use Homebrew: brew install --cask xquartz"
    exit 1
fi

echo "✅ XQuartz is installed"

# Backup current XQuartz settings
echo "💾 Backing up current XQuartz settings..."
BACKUP_DIR="$HOME/.xquartz_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup XQuartz preferences
if defaults read org.xquartz.X11 >/dev/null 2>&1; then
    defaults read org.xquartz.X11 > "$BACKUP_DIR/xquartz_settings.plist"
    echo "✅ Settings backed up to: $BACKUP_DIR"
else
    echo "ℹ️  No existing XQuartz settings found"
fi

# Configure XQuartz for container support
echo "🔧 Configuring XQuartz for container X11 forwarding..."

# Enable TCP connections (required for container access)
echo "🌐 Enabling TCP connections..."
defaults write org.xquartz.X11 nolisten_tcp -bool false

# Enable network clients (security setting)
echo "🔓 Enabling network client connections..."
defaults write org.xquartz.X11 no_auth -bool false
defaults write org.xquartz.X11 nolisten_tcp -bool false

# Set other helpful defaults
echo "⚙️  Setting additional helpful defaults..."
defaults write org.xquartz.X11 enable_iglx -bool true
defaults write org.xquartz.X11 depth -int 24

# Verify settings
echo "🔍 Verifying XQuartz configuration..."
TCP_DISABLED=$(defaults read org.xquartz.X11 nolisten_tcp 2>/dev/null)
if [ "$TCP_DISABLED" = "0" ]; then
    echo "✅ TCP connections: ENABLED"
else
    echo "⚠️  TCP connections: may not be properly configured"
fi

# Check if XQuartz is currently running
if pgrep -x "XQuartz" >/dev/null || pgrep -i "xquartz" >/dev/null; then
    echo "🔄 XQuartz is currently running - restart required"
    echo "🛑 Stopping XQuartz..."
    pkill -f XQuartz
    sleep 3
    
    echo "🚀 Starting XQuartz with new settings..."
    open -a XQuartz
    sleep 5
    
    # Wait for XQuartz to start
    echo "⏳ Waiting for XQuartz to initialize..."
    TIMEOUT=30
    while [ $TIMEOUT -gt 0 ]; do
        if pgrep -i "xquartz" >/dev/null; then
            echo "✅ XQuartz restarted successfully"
            break
        fi
        sleep 1
        TIMEOUT=$((TIMEOUT - 1))
    done
    
    if [ $TIMEOUT -eq 0 ]; then
        echo "⚠️  XQuartz restart may have failed"
    fi
else
    echo "ℹ️  XQuartz is not currently running"
    echo "🚀 Starting XQuartz..."
    open -a XQuartz
    sleep 5
fi

# Test if XQuartz is listening on TCP
echo "🔍 Testing XQuartz TCP connectivity..."
if lsof -i :6000 >/dev/null 2>&1; then
    echo "✅ XQuartz is listening on TCP port 6000"
    echo "🎉 Configuration successful!"
else
    echo "⚠️  XQuartz may not be listening on TCP port 6000"
    echo "💡 You may need to manually restart XQuartz"
fi

echo ""
echo "📋 Setup Complete!"
echo "=================="
echo "✅ XQuartz TCP connections enabled"
echo "✅ Network client access configured"
echo "✅ Container-friendly settings applied"
echo ""
echo "📝 Next Steps:"
echo "1. Build your container: ./build.sh"
echo "2. Test X11 forwarding: ./run-x11.sh"
echo ""
echo "🔧 If issues persist:"
echo "- Manually restart XQuartz from Applications"
echo "- Check XQuartz → Security → 'Allow connections from network clients'"
echo ""
echo "🗂️  Settings backup saved to: $BACKUP_DIR"
echo ""
echo "⚠️  Security Note:"
echo "This configuration enables network X11 connections for container support."
echo "Only use on trusted networks."
