#!/bin/bash

# Build script for Fedora GUI container
# This script builds a Podman container image called 'fedora_gui'

echo "Building Fedora GUI container image..."

podman build -t fedora_gui .

if [ $? -eq 0 ]; then
    echo "✅ Successfully built fedora_gui container image"
    echo "You can now run the container using:"
    echo "  ./run-x11.sh     (for X11 support)"
    echo "  ./run-wayland.sh (for Wayland support)"
else
    echo "❌ Failed to build container image"
    exit 1
fi
