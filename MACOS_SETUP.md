# macOS Setup Guide for Fedora GUI Container

This guide explains how to run GUI applications from Linux containers on macOS using XQuartz and Podman.

## 🍎 Prerequisites

### Required Software
1. **XQuartz** - X11 display server for macOS
   ```bash
   # Install via Homebrew (recommended)
   brew install --cask xquartz
   
   # Or download from: https://www.xquartz.org/
   ```

2. **Podman** - Container runtime
   ```bash
   # Install via Homebrew
   brew install podman
   
   # Initialize podman machine
   podman machine init
   podman machine start
   ```

## 🛠️ Automated Setup (Recommended)

Use the provided setup script to automatically configure XQuartz:

```bash
# Make setup script executable
chmod +x setup-macos.sh

# Run the setup script
./setup-macos.sh
```

The script will:
- ✅ Check XQuartz installation
- ✅ Backup current settings
- ✅ Enable TCP connections
- ✅ Configure network client access
- ✅ Restart XQuartz with new settings

## 🔧 Manual Setup (Alternative)

If you prefer to configure manually:

### Step 1: Configure XQuartz Settings

1. **Enable TCP connections:**
   ```bash
   defaults write org.xquartz.X11 nolisten_tcp -bool false
   ```

2. **Open XQuartz Preferences:**
   - Launch XQuartz
   - Go to `XQuartz → Preferences`
   - Click the `Security` tab
   - ✅ Check "Allow connections from network clients"

3. **Restart XQuartz:**
   ```bash
   pkill -f XQuartz
   open -a XQuartz
   ```

### Step 2: Verify Configuration

Check that XQuartz is listening on TCP port 6000:
```bash
lsof -i :6000
```

You should see XQuartz listening on port 6000.

## 🚀 Usage

### Build the Container
```bash
# Make build script executable
chmod +x build.sh

# Build the Fedora GUI container
./build.sh
```

### Run GUI Applications
```bash
# Make run script executable  
chmod +x run-x11.sh

# Run the default app (xeyes)
./run-x11.sh

# Run other GUI applications
./run-x11.sh gedit
./run-x11.sh firefox
./run-x11.sh gnome-calculator
```

## 🔍 How It Works

### The Problem
- Linux containers use Unix domain sockets for X11
- macOS containers can't access Unix sockets from the host
- XQuartz creates sockets in complex paths like `/private/tmp/.../org.xquartz:0`

### The Solution
1. **TCP-based X11 forwarding** instead of Unix socket mounting
2. **Network connections** using `host.containers.internal:0`
3. **XQuartz TCP mode** enabled via configuration
4. **Host networking** for the container (`--net=host`)

### Technical Details
The `run-x11.sh` script:
- Detects macOS and configures for XQuartz
- Checks if XQuartz TCP is enabled
- Uses `host.containers.internal:0` as DISPLAY
- Applies broad `xhost` permissions for access
- Runs container with host networking

## ⚠️ Security Considerations

### What This Setup Does
- Enables TCP X11 connections (port 6000)
- Allows network clients to connect to XQuartz
- Uses broad host access permissions

### Security Recommendations
- **Use only on trusted networks**
- **Disable when not needed:**
  ```bash
  defaults write org.xquartz.X11 nolisten_tcp -bool true
  ```
- **Consider VPN** when using on public networks

## 🐛 Troubleshooting

### "XQuartz is not running"
```bash
# Start XQuartz manually
open -a XQuartz

# Wait a few seconds, then try again
./run-x11.sh
```

### "Can't open display"
1. **Check XQuartz TCP:**
   ```bash
   lsof -i :6000
   ```
   If nothing shows, run the setup script again.

2. **Check DISPLAY variable inside container:**
   ```bash
   ./run-x11.sh /bin/bash
   echo $DISPLAY  # Should show host.containers.internal:0
   ```

3. **Verify network access:**
   ```bash
   ./run-x11.sh ping host.containers.internal
   ```

### "Operation not supported" 
This usually means the script is trying to use Unix sockets. Make sure:
- XQuartz TCP is enabled
- The script detects macOS correctly
- You're using the latest version of the run script

### Performance Issues
- GUI apps may be slower over network X11
- Consider using VNC for complex applications
- Some OpenGL apps may not work perfectly

## 📝 Configuration Files

### XQuartz Settings Location
```bash
# View current settings
defaults read org.xquartz.X11

# Key settings for containers
defaults read org.xquartz.X11 nolisten_tcp  # Should be 0 (false)
```

### Backup and Restore
The setup script creates backups in `~/.xquartz_backup_TIMESTAMP/`

To restore original settings:
```bash
# Find your backup
ls ~/.xquartz_backup_*

# Restore from backup
defaults delete org.xquartz.X11
defaults import org.xquartz.X11 ~/.xquartz_backup_TIMESTAMP/xquartz_settings.plist
```

## 🎯 Testing

### Quick Test
```bash
# Test with xeyes (should show animated eyes)
./run-x11.sh

# Test with text editor
./run-x11.sh gedit
```

### Advanced Test
```bash
# Test X11 forwarding with diagnostic info
./run-x11.sh sh -c "echo 'DISPLAY: $DISPLAY' && xdpyinfo"
```

## 📚 Additional Resources

- [XQuartz Official Documentation](https://www.xquartz.org/)
- [Podman Desktop for macOS](https://podman-desktop.io/)
- [X11 Forwarding Best Practices](https://wiki.archlinux.org/title/X11_forwarding)

## 🆘 Getting Help

If you encounter issues:

1. **Run the setup script again:** `./setup-macos.sh`
2. **Check XQuartz version:** Ensure you have XQuartz 2.8.0+
3. **Restart everything:**
   ```bash
   pkill -f XQuartz
   podman machine stop
   podman machine start
   open -a XQuartz
   ```
4. **Create an issue** with the output of:
   ```bash
   ./run-x11.sh sh -c "echo 'DISPLAY: $DISPLAY' && uname -a"
   ```

---

*This setup enables powerful cross-platform GUI development using Linux containers on macOS! 🚀*
