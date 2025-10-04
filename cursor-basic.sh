#!/bin/bash
export LIBGL_ALWAYS_SOFTWARE=1
export ELECTRON_DISABLE_GPU=1
mkdir -p /home/user/.cursor-basic
exec cursor --disable-gpu --no-sandbox --disable-extensions --disable-workspace-trust --skip-welcome --user-data-dir=/home/user/.cursor-basic "$@"
