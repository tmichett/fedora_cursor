#!/bin/bash

# Interactive script to test Cursor rendering inside the container

echo "🔍 Testing Cursor rendering diagnostics..."

echo "Step 1: Testing basic X11 connection..."
./run-x11.sh bash -c "
    echo 'Inside container:'
    echo '  DISPLAY: \$DISPLAY'
    echo '  Testing xeyes...'
    timeout 5 xeyes &
    sleep 2
    echo '  Did you see xeyes? (This confirms X11 works)'
    echo ''
    echo 'Step 2: Testing Cursor with verbose output...'
    echo '  Running: cursor-safe --verbose /workspace'
    timeout 15 cursor-safe --verbose /workspace 2>&1 | tail -20
    echo ''
    echo 'Step 3: Cursor environment check...'
    echo '  OpenGL info:'
    glxinfo | grep -E 'renderer|version' 2>/dev/null || echo 'No glxinfo available'
    echo '  Font check:'
    fc-list | head -5 2>/dev/null || echo 'No fc-list available'
    echo ''
    echo 'Diagnostic complete!'
" "$@"
