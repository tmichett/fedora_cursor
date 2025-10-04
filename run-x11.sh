#!/bin/bash

# Run script for Fedora GUI container with X11 support
# This script runs the fedora_gui container with X11 forwarding

echo "Starting Fedora GUI container with X11 support..."

# Check if DISPLAY is set
if [ -z "$DISPLAY" ]; then
    echo "❌ DISPLAY environment variable is not set"
    echo "Please ensure X11 is running and DISPLAY is exported"
    exit 1
fi

# Detect operating system and set appropriate X11 socket path
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WSL_DISTRO_NAME" ]]; then
    # Windows (Git Bash, Cygwin, or WSL)
    echo "🖥️  Detected Windows environment - configuring for X11 server"
    
    # Check if DISPLAY uses Windows format
    if [[ "$DISPLAY" == *"host.docker.internal"* || "$DISPLAY" == *"host.containers.internal"* || "$DISPLAY" == "localhost:0" ]]; then
        echo "✅ Windows DISPLAY format detected: $DISPLAY"
    else
        echo "⚠️  Setting Windows-compatible DISPLAY format"
        # Auto-detect container runtime and set appropriate DISPLAY
        if command -v podman >/dev/null 2>&1; then
            export DISPLAY="host.containers.internal:0"
        else
            export DISPLAY="host.docker.internal:0"
        fi
        echo "🔧 DISPLAY set to: $DISPLAY"
    fi
    
    # Check if X11 server is running (Windows)
    if command -v netstat >/dev/null 2>&1; then
        if netstat -an | grep -q ":6000"; then
            echo "✅ X11 server is running on port 6000"
        else
            echo "❌ X11 server is not running on port 6000"
            echo ""
            echo "🚀 Please start your X11 server:"
            echo "   • VcXsrv: Run XLaunch, enable 'Disable access control'"
            echo "   • X410: Launch from Microsoft Store"
            echo "   • Xming: Run with -ac parameter"
            echo "   • MobaXterm: Ensure X server is active"
            echo ""
            echo "🔧 Or run: setup-windows.ps1"
            exit 1
        fi
    fi
    
    # Windows networking approach
    echo "🌐 Using Windows network-based X11 forwarding"
    
    # Build container command for Windows
    if command -v podman >/dev/null 2>&1; then
        echo "🐳 Using Podman"
        podman run --rm -it \
            -e DISPLAY="$DISPLAY" \
            --add-host=host.containers.internal:host-gateway \
            fedora_gui "$@"
    else
        echo "🐳 Using Docker"
        docker run --rm -it \
            -e DISPLAY="$DISPLAY" \
            fedora_gui "$@"
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS with XQuartz
    echo "🍎 Detected macOS - configuring for XQuartz"
    
    # Check if XQuartz is running (case-sensitive check)
    if ! pgrep -x "XQuartzApplications" > /dev/null && ! pgrep -x "Xquartz" > /dev/null && ! pgrep -i "xquartz" > /dev/null; then
        echo "❌ XQuartz is not running"
        echo "Please start XQuartz and try again"
        exit 1
    fi
    echo "✅ XQuartz is running"
    
    # Handle XQuartz socket path
    echo "🔧 Configuring XQuartz socket access..."
    
    # Enable network access for XQuartz
    echo "Enabling XQuartz network access..."
    /opt/X11/bin/xhost +localhost 2>/dev/null || echo "Note: xhost command may not be available"
    
    # Check if XQuartz is listening on TCP port 6000
    if lsof -i :6000 >/dev/null 2>&1; then
        echo "✅ XQuartz is listening on TCP port 6000"
        USE_TCP=true
    else
        echo "⚠️  XQuartz is not listening on TCP port 6000"
        echo "💡 This is normal - XQuartz disabled TCP by default for security"
        USE_TCP=false
    fi
    
    if [ "$USE_TCP" = true ]; then
        # TCP-based approach
        echo "Using TCP-based X11 forwarding..."
        CONTAINER_DISPLAY="host.containers.internal:0"
        
        echo "Running: podman run --rm -it -e DISPLAY=$CONTAINER_DISPLAY --add-host=host.containers.internal:host-gateway fedora_gui $@"
        
        podman run --rm -it \
            -e DISPLAY="$CONTAINER_DISPLAY" \
            --add-host=host.containers.internal:host-gateway \
            fedora_gui "$@"
    else
        # Socket-based approach with macOS-specific handling
        echo "Using Unix socket approach..."
        
        # Get the actual display number
        DISPLAY_NUM=$(echo $DISPLAY | sed 's/.*:\([0-9]*\).*/\1/')
        
        # Try to find the actual socket path
        SOCKET_PATH="/tmp/.X11-unix/X${DISPLAY_NUM}"
        
        echo "Looking for X11 socket at: $SOCKET_PATH"
        if [ -S "$SOCKET_PATH" ]; then
            echo "✅ Found X11 socket"
        else
            echo "⚠️  Creating socket directory if needed..."
            sudo mkdir -p /tmp/.X11-unix 2>/dev/null || mkdir -p /tmp/.X11-unix
            
            # Give it a moment for XQuartz to create the socket
            sleep 1
            
            if [ ! -S "$SOCKET_PATH" ]; then
                echo "❌ Socket still not found. Trying alternative approach..."
                # Use the original DISPLAY but with localhost access
                echo "Trying with original DISPLAY: $DISPLAY"
                
                echo "Running: podman run --rm -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --net=host fedora_gui $@"
                
                podman run --rm -it \
                    -e DISPLAY="$DISPLAY" \
                    -v /tmp/.X11-unix:/tmp/.X11-unix \
                    --net=host \
                    fedora_gui "$@"
                
                # Clean up and exit
                /opt/X11/bin/xhost -localhost 2>/dev/null || true
                return
            fi
        fi
        
        # Set up X11 authentication
        XAUTH_FILE="$HOME/.Xauthority"
        # Try a location that's more likely to be accessible to podman
        CONTAINER_XAUTH="$HOME/.container_xauth_$$"
        
        # Create a temporary xauth file for the container
        if [ -f "$XAUTH_FILE" ]; then
            echo "Setting up X11 authentication..."
            
            # Create container xauth file
            touch "$CONTAINER_XAUTH"
            chmod 644 "$CONTAINER_XAUTH"
            
            # Extract auth info and add to container auth file
            echo "Extracting X11 auth token..."
            echo "🔍 Current DISPLAY: $DISPLAY"
            
            # Try different methods to extract the auth token
            AUTH_TOKEN=""
            
            # Method 1: Try with the full DISPLAY path
            if [ -z "$AUTH_TOKEN" ]; then
                AUTH_TOKEN=$(/opt/X11/bin/xauth list "$DISPLAY" 2>/dev/null | awk '{print $3}' | head -1)
                [ -n "$AUTH_TOKEN" ] && echo "✅ Got auth token via full DISPLAY path"
            fi
            
            # Method 2: Try with just the display number
            if [ -z "$AUTH_TOKEN" ]; then
                AUTH_TOKEN=$(/opt/X11/bin/xauth list ":${DISPLAY_NUM}" 2>/dev/null | awk '{print $3}' | head -1)
                [ -n "$AUTH_TOKEN" ] && echo "✅ Got auth token via display number"
            fi
            
            # Method 3: Try listing all and grep for the display
            if [ -z "$AUTH_TOKEN" ]; then
                AUTH_TOKEN=$(/opt/X11/bin/xauth list 2>/dev/null | grep ":${DISPLAY_NUM}" | awk '{print $3}' | head -1)
                [ -n "$AUTH_TOKEN" ] && echo "✅ Got auth token via grep search"
            fi
            
            # Method 4: Extract from the complex XQuartz path
            if [ -z "$AUTH_TOKEN" ]; then
                XQUARTZ_DISPLAY=$(echo "$DISPLAY" | sed 's|/private/tmp/.*/org\.xquartz|localhost|')
                AUTH_TOKEN=$(/opt/X11/bin/xauth list "$XQUARTZ_DISPLAY" 2>/dev/null | awk '{print $3}' | head -1)
                [ -n "$AUTH_TOKEN" ] && echo "✅ Got auth token via XQuartz path conversion"
            fi
            
            if [ -n "$AUTH_TOKEN" ]; then
                echo "🎫 Auth token found: ${AUTH_TOKEN:0:8}..."
                
                # Add auth entries for different display formats
                echo "🔑 Adding auth entries to container file..."
                
                # Clear any existing auth file and create a fresh one for the container
                > "$CONTAINER_XAUTH"
                
                echo "🔑 Creating container-specific auth entries..."
                
                # Try a simpler approach - just copy the existing auth but modify the display name
                echo "Trying simplified auth approach..."
                
                # Method 1: Add the simple :0 entry (most important)
                echo "Adding :${DISPLAY_NUM} entry..."
                if /opt/X11/bin/xauth -f "$CONTAINER_XAUTH" add :${DISPLAY_NUM} MIT-MAGIC-COOKIE-1 $AUTH_TOKEN; then
                    echo "✅ Successfully added :${DISPLAY_NUM}"
                else
                    echo "❌ Failed to add :${DISPLAY_NUM}"
                fi
                
                # Method 2: Add localhost entry
                echo "Adding localhost:${DISPLAY_NUM} entry..."
                if /opt/X11/bin/xauth -f "$CONTAINER_XAUTH" add localhost:${DISPLAY_NUM} MIT-MAGIC-COOKIE-1 $AUTH_TOKEN; then
                    echo "✅ Successfully added localhost:${DISPLAY_NUM}"
                else
                    echo "❌ Failed to add localhost:${DISPLAY_NUM}"
                fi
                
                # Alternative approach: Just use xhost permissions and skip complex auth
                echo "🛡️ Using simplified xhost-based authentication..."
                /opt/X11/bin/xhost +SI:localuser:$(whoami) 2>/dev/null || true
                /opt/X11/bin/xhost +local: 2>/dev/null || true
                
                echo "✅ Container auth setup complete"
                
                # Verify the file was created and has content
                if [ -f "$CONTAINER_XAUTH" ] && [ -s "$CONTAINER_XAUTH" ]; then
                    echo "✅ X11 auth file created successfully at: $CONTAINER_XAUTH"
                    echo "📁 File size: $(wc -c < "$CONTAINER_XAUTH") bytes"
                    echo "📋 Auth file contents:"
                    /opt/X11/bin/xauth -f "$CONTAINER_XAUTH" list 2>/dev/null || echo "Could not list auth contents"
                    
                    # Double-check file exists right before use
                    echo "🔍 Final file check before container mount:"
                    ls -la "$CONTAINER_XAUTH"
                else
                    echo "❌ Failed to create auth file, falling back to xhost permissions"
                    # Use broader xhost permissions as fallback
                    /opt/X11/bin/xhost +local: 2>/dev/null || true
                    rm -f "$CONTAINER_XAUTH"
                    CONTAINER_XAUTH=""
                fi
            else
                echo "⚠️  Could not extract auth token with any method"
                echo "🔧 Trying alternative: adding local host to access control"
                
                # Use broader xhost permissions as fallback
                /opt/X11/bin/xhost +local: 2>/dev/null || true
                /opt/X11/bin/xhost +localhost 2>/dev/null || true
                /opt/X11/bin/xhost +$(hostname) 2>/dev/null || true
                
                rm -f "$CONTAINER_XAUTH"
                CONTAINER_XAUTH=""
            fi
            
            # Additional fallback - use more permissive xhost settings
            echo "🛡️  Adding additional permissive access controls..."
            /opt/X11/bin/xhost +local: 2>/dev/null || true
            /opt/X11/bin/xhost +localhost 2>/dev/null || true
            /opt/X11/bin/xhost +127.0.0.1 2>/dev/null || true
        else
            echo "⚠️  No .Xauthority file found, trying without authentication..."
            CONTAINER_XAUTH=""
        fi
        
        # Build the podman command - use host networking and original DISPLAY
        echo "🎯 Using original DISPLAY path for maximum compatibility: $DISPLAY"
        
        # Extract the actual XQuartz socket directory from DISPLAY
        XQUARTZ_SOCKET_DIR=$(dirname "$DISPLAY")
        echo "🔌 XQuartz socket directory: $XQUARTZ_SOCKET_DIR"
        
        # Try network-based approach since Unix sockets don't work well between macOS and Linux containers
        echo "🌐 Using network-based approach due to macOS/Linux socket incompatibility"
        
        # Enable TCP connections in XQuartz temporarily
        echo "🔓 Temporarily enabling XQuartz TCP connections..."
        /opt/X11/bin/xhost +localhost
        /opt/X11/bin/xhost +127.0.0.1
        /opt/X11/bin/xhost +$(hostname)
        
        # Use localhost:0 instead of the socket path
        CONTAINER_DISPLAY="localhost:0"
        
        PODMAN_CMD="podman run --rm -it \
            --net=host \
            --user=root \
            -e DISPLAY=\"$CONTAINER_DISPLAY\" \
            -v /tmp/.X11-unix:/tmp/.X11-unix"
        
        # Skip auth file for now - rely on xhost permissions
        echo "🛡️ Skipping auth file, using xhost permissions only for simplicity"
        echo "🔧 This often works better with XQuartz on macOS"
        
        # Ensure we have broad xhost permissions 
        /opt/X11/bin/xhost +local: 2>/dev/null || true
        /opt/X11/bin/xhost +localhost 2>/dev/null || true
        /opt/X11/bin/xhost +127.0.0.1 2>/dev/null || true
        /opt/X11/bin/xhost +SI:localuser:$(whoami) 2>/dev/null || true
        
        # Don't mount any auth file - let it use default behavior
        CONTAINER_XAUTH=""
        
        PODMAN_CMD="$PODMAN_CMD fedora_gui $@"
        
        echo "Running: $PODMAN_CMD"
        
        # Execute the command and capture result
        eval $PODMAN_CMD
        PODMAN_RESULT=$?
        
        # Clean up temp xauth file only after podman finishes
        if [ -n "$CONTAINER_XAUTH" ] && [ -f "$CONTAINER_XAUTH" ]; then
            echo "🧹 Cleaning up temp auth file: $CONTAINER_XAUTH"
            rm -f "$CONTAINER_XAUTH"
        fi
        
        # Return the podman result
        if [ $PODMAN_RESULT -eq 0 ]; then
            echo "✅ Container exited successfully"
        else
            echo "❌ Container exited with code: $PODMAN_RESULT"
        fi
    fi
    
    # Clean up - re-enable access control
    echo "Cleaning up XQuartz access..."
    /opt/X11/bin/xhost -localhost 2>/dev/null || true
        
else
    # Linux
    echo "🐧 Detected Linux - using standard X11 configuration"
    
    # Check if X11 socket exists
    if [ ! -S /tmp/.X11-unix/X0 ]; then
        echo "⚠️  Warning: X11 socket not found at /tmp/.X11-unix/X0"
        echo "Make sure X11 is running properly"
    fi
    
    echo "Running: podman run --rm -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix fedora_gui $@"
    
    # Run the container with X11 support (Linux)
    podman run --rm -it \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        fedora_gui "$@"
fi
