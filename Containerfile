# Use the latest Fedora base image
FROM fedora:latest

# Add Cursor repository
RUN echo -e "[cursor]\n\
name=Cursor\n\
baseurl=https://downloads.cursor.com/yumrepo\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://downloads.cursor.com/keys/anysphere.asc\n\
repo_gpgcheck=1" > /etc/yum.repos.d/cursor.repo

# Update the system and install GUI apps with dependencies for Electron apps
RUN dnf update -y && \
    dnf install -y \
        xeyes gedit cursor xterm \
        hostname \
        dbus-x11 \
        mesa-dri-drivers mesa-libGL mesa-libEGL \
        libXrandr libXScrnSaver \
        gtk3 gtk3-devel \
        nss \
        alsa-lib \
        liberation-fonts dejavu-sans-fonts \
        xorg-x11-fonts-misc \
        vulkan-loader \
        libdrm \
        cairo cairo-devel \
        pango pango-devel && \
    dnf clean all

# Create working wrapper script for Cursor with improved rendering support
RUN echo '#!/bin/bash' > /usr/local/bin/cursor-safe && \
    echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> /usr/local/bin/cursor-safe && \
    echo 'export GALLIUM_DRIVER=llvmpipe' >> /usr/local/bin/cursor-safe && \
    echo 'export MESA_GL_VERSION_OVERRIDE=3.3' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_GPU=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_USE_SYSTEM_FONT_FALLBACK=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_GPU=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_HARDWARE_ACCELERATION=1' >> /usr/local/bin/cursor-safe && \
    echo 'export CHROMIUM_DISABLE_GPU=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_MAX_HEAP_SIZE=4096' >> /usr/local/bin/cursor-safe && \
    echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> /usr/local/bin/cursor-safe && \
    echo 'mkdir -p /home/user/.cursor-data' >> /usr/local/bin/cursor-safe && \
    echo 'exec cursor --disable-gpu --no-sandbox --disable-extensions --disable-dev-shm-usage --user-data-dir=/home/user/.cursor-data "$@"' >> /usr/local/bin/cursor-safe && \
    chmod +x /usr/local/bin/cursor-safe

# Create a non-root user to run the application
# Running GUI apps as root is a security risk
RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user

# Set the default command to run our test application
CMD ["xeyes"]