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
        mesa-dri-drivers \
        libXrandr \
        libXScrnSaver \
        gtk3 \
        nss \
        alsa-lib && \
    dnf clean all

# Create wrapper script for Cursor with container-compatible settings
RUN echo '#!/bin/bash' > /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_SANDBOX=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_NO_ATTACH_CONSOLE=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_SECURITY_WARNINGS=1' >> /usr/local/bin/cursor-safe && \
    echo 'export ELECTRON_DISABLE_GPU_SANDBOX=1' >> /usr/local/bin/cursor-safe && \
    echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> /usr/local/bin/cursor-safe && \
    echo 'export DISPLAY=${DISPLAY}' >> /usr/local/bin/cursor-safe && \
    echo 'exec cursor --disable-gpu --disable-chromium-sandbox "$@"' >> /usr/local/bin/cursor-safe && \
    chmod +x /usr/local/bin/cursor-safe

# Create a non-root user to run the application
# Running GUI apps as root is a security risk
RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user

# Set the default command to run our test application
CMD ["xeyes"]