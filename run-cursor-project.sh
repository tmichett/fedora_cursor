#!/bin/bash

# Enhanced script for running Cursor with a mounted project directory
# Usage: ./run-cursor-project.sh /path/to/your/project

echo "🎯 Enhanced Cursor launcher with project mounting"

if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/project/directory"
    echo "Example: $0 /Users/travis/Github/my-project"
    exit 1
fi

PROJECT_DIR="$1"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

echo "📁 Mounting project: $PROJECT_DIR"

# Detect OS and set display
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS with XQuartz
    echo "🍎 macOS detected - configuring for XQuartz"
    
    # Check XQuartz
    if ! pgrep -i "xquartz" > /dev/null; then
        echo "❌ XQuartz is not running"
        echo "Please start XQuartz and try again"
        exit 1
    fi
    
    # Enable network access
    /opt/X11/bin/xhost +localhost 2>/dev/null || true
    
    # Check if TCP is enabled
    if lsof -i :6000 >/dev/null 2>&1; then
        echo "✅ XQuartz TCP enabled"
        DISPLAY_VAR="host.containers.internal:0"
        NETWORK_ARGS="--add-host=host.containers.internal:host-gateway"
    else
        echo "❌ XQuartz TCP not enabled. Please run: ./setup-macos.sh"
        exit 1
    fi
    
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WSL_DISTRO_NAME" ]]; then
    # Windows
    echo "🖥️  Windows detected"
    DISPLAY_VAR="${DISPLAY:-host.containers.internal:0}"
    NETWORK_ARGS="--add-host=host.containers.internal:host-gateway"
    
else
    # Linux
    echo "🐧 Linux detected"
    DISPLAY_VAR="${DISPLAY:-:0}"
    NETWORK_ARGS="-v /tmp/.X11-unix:/tmp/.X11-unix"
fi

echo "🖥️  Display: $DISPLAY_VAR"

# Run with enhanced settings and project mounting
echo "🚀 Starting Cursor with mounted project directory..."

podman run --rm -it \
    -e DISPLAY="$DISPLAY_VAR" \
    $NETWORK_ARGS \
    --cap-add=SYS_ADMIN \
    --security-opt seccomp=unconfined \
    --security-opt apparmor=unconfined \
    --shm-size=8g \
    -v /dev/shm:/dev/shm \
    -v /tmp:/tmp \
    -v "$PROJECT_DIR:/workspace:Z" \
    -v "$HOME/.cursor-container-persistent:/home/user/.cursor" \
    -w /workspace \
    fedora_gui bash -c "
        echo 'Container started successfully!'
        echo 'Project directory contents:'
        ls -la /workspace
        echo ''
        echo 'Starting Cursor...'
        cursor-safe /workspace
        echo 'Cursor finished. Container will stay alive for 30 seconds...'
        sleep 30
    "

# Cleanup
if [[ "$OSTYPE" == "darwin"* ]]; then
    /opt/X11/bin/xhost -localhost 2>/dev/null || true
fi

echo "🧹 Container session ended"
