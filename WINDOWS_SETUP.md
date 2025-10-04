# Windows Setup Guide for Fedora GUI Container

This guide explains how to run GUI applications from Linux containers on Windows using X11 servers and Docker/Podman.

## 🖥️ Prerequisites

### Required Software
1. **X11 Server** - Choose one:
   - **VcXsrv** (Recommended, free): https://sourceforge.net/projects/vcxsrv/
   - **X410** (Microsoft Store, paid): https://apps.microsoft.com/store/detail/x410/9NLP712ZMN9Q
   - **Xming** (Free/paid): https://sourceforge.net/projects/xming/
   - **MobaXterm** (Free/paid): https://mobaxterm.mobatek.net/

2. **Container Runtime** - Choose one:
   - **Docker Desktop** (Recommended): https://www.docker.com/products/docker-desktop/
   - **Podman** (Alternative): https://podman.io/getting-started/installation#windows

## 🛠️ Automated Setup (Recommended)

Use the provided PowerShell setup script:

```powershell
# Run PowerShell as Administrator (optional but recommended)
# Navigate to your project directory
cd path\to\fedora_cursor

# Run the setup script
.\setup-windows.ps1
```

The script will:
- ✅ Detect installed X11 servers
- ✅ Check if X11 server is running on port 6000
- ✅ Configure DISPLAY environment variable
- ✅ Detect container runtime (Docker/Podman)
- ✅ Test X11 connectivity

## 🔧 Manual Setup (Alternative)

### Step 1: Install and Configure X11 Server

#### Option A: VcXsrv (Recommended)
1. **Download and install VcXsrv** from SourceForge
2. **Run XLaunch** from Start Menu
3. **Configuration wizard:**
   - Display settings: ✅ **Multiple windows** → Next
   - Session type: ✅ **Start no client** → Next  
   - Extra settings: ✅ **Disable access control** → Next
   - Click **Finish**

#### Option B: X410
1. **Install from Microsoft Store**
2. **Launch X410** from Start Menu
3. **X410 runs automatically** with appropriate settings

#### Option C: Other X11 Servers
- **Xming**: Run with `-ac` parameter to disable access control
- **MobaXterm**: Start MobaXterm and ensure X11 server is active

### Step 2: Set Environment Variables

```powershell
# For Docker Desktop
$env:DISPLAY = "host.docker.internal:0"

# For Podman
$env:DISPLAY = "host.containers.internal:0"

# Make it persistent (optional)
[System.Environment]::SetEnvironmentVariable("DISPLAY", "host.docker.internal:0", [System.EnvironmentVariableTarget]::User)
```

### Step 3: Verify Configuration

Check X11 server is listening:
```powershell
Get-NetTCPConnection -LocalPort 6000
# Should show X11 server listening on port 6000
```

## 🚀 Usage

### Build the Container
```bash
# Using bash (Git Bash, WSL, etc.)
chmod +x build.sh
./build.sh

# OR using PowerShell (if you create build.ps1)
.\build.ps1
```

### Run GUI Applications

#### Using Bash Scripts (Git Bash, WSL)
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

#### Using PowerShell Scripts
```powershell
# Run the default app (xeyes)
.\run-x11.ps1

# Run other GUI applications
.\run-x11.ps1 gedit
.\run-x11.ps1 firefox
.\run-x11.ps1 gnome-calculator
```

#### Direct Container Commands
```bash
# Docker
docker run --rm -it -e DISPLAY=host.docker.internal:0 fedora_gui

# Podman  
podman run --rm -it -e DISPLAY=host.containers.internal:0 --add-host=host.containers.internal:host-gateway fedora_gui
```

## 🔍 How It Works

### The Challenge
- Windows doesn't have native X11 support
- Linux containers need X11 display server for GUI apps
- Container networking needs to reach Windows host

### The Solution
1. **X11 Server on Windows** - VcXsrv, X410, etc. provide X11 compatibility
2. **Network-based forwarding** - Uses TCP instead of Unix sockets
3. **Special hostnames** - `host.docker.internal` / `host.containers.internal`
4. **Disabled access control** - Allows container connections

### Technical Details
- **VcXsrv/X410** acts as X11 display server on Windows
- **Container DISPLAY** points to `host.*.internal:0`
- **TCP port 6000** used for X11 communication
- **Access control disabled** to allow container connections

## 🐳 Container Runtime Differences

| Feature | Docker Desktop | Podman |
|---------|----------------|---------|
| **Host Resolution** | `host.docker.internal` | `host.containers.internal` |
| **Network Flag** | `--net=host` (optional) | `--add-host=host.containers.internal:host-gateway` |
| **Installation** | GUI installer | CLI-focused |
| **Resource Usage** | Higher (includes VM) | Lower (native) |

## ⚠️ Security Considerations

### What This Setup Does
- Disables X11 access control (allows any connection)
- Opens TCP port 6000 for X11 communication
- Exposes display server to container network

### Security Recommendations
- **Use only on trusted networks**
- **Close X11 server when not needed**
- **Consider firewall rules** for port 6000
- **Use VPN** on public networks

## 🐛 Troubleshooting

### "DISPLAY environment variable is not set"
```powershell
# Set DISPLAY variable
$env:DISPLAY = "host.docker.internal:0"  # or host.containers.internal:0

# Check it's set
echo $env:DISPLAY
```

### "X11 server is not running on port 6000"
1. **Start your X11 server:**
   - VcXsrv: Run XLaunch from Start Menu
   - X410: Launch from Microsoft Store
   - Xming: Run with `-ac` parameter

2. **Check it's listening:**
   ```powershell
   Get-NetTCPConnection -LocalPort 6000
   ```

### "Can't open display"
1. **Verify DISPLAY format:**
   ```bash
   echo $DISPLAY  # Should be host.*.internal:0
   ```

2. **Check access control is disabled** in your X11 server settings

3. **Test connectivity:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 6000
   ```

### "Container can't resolve host.*.internal"
- **Docker**: Ensure Docker Desktop is running
- **Podman**: Use `--add-host=host.containers.internal:host-gateway`

### Performance Issues
- X11 over network can be slower than native
- **Hardware acceleration** may not work for all applications
- Consider **VNC** for graphics-intensive applications

### WSL-Specific Issues
```bash
# In WSL, you might need:
export DISPLAY="$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0"

# Or use WSLg (Windows 11)
# WSL2 with WSLg has built-in GUI support
```

## 🎯 Platform-Specific Notes

### Windows 10
- Requires separate X11 server installation
- Docker Desktop or Podman needed
- Manual DISPLAY configuration

### Windows 11 with WSL2
- **WSLg available** - built-in GUI support for WSL2
- Still can use X11 servers for non-WSL containers
- Better performance with WSLg for WSL2 applications

### Different Shells
```bash
# Git Bash
export DISPLAY=host.docker.internal:0
./run-x11.sh

# PowerShell
$env:DISPLAY = "host.docker.internal:0"
.\run-x11.ps1

# Command Prompt
set DISPLAY=host.docker.internal:0
bash run-x11.sh
```

## 📚 Additional Resources

- [VcXsrv Documentation](https://sourceforge.net/projects/vcxsrv/)
- [X410 User Guide](https://x410.dev/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/)
- [Podman Windows Installation](https://podman.io/getting-started/installation#windows)
- [WSLg Documentation](https://github.com/microsoft/wslg)

## 🆘 Getting Help

If you encounter issues:

1. **Run the setup script:** `.\setup-windows.ps1`
2. **Check X11 server logs** (usually in system tray)
3. **Test basic connectivity:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 6000
   ```
4. **Verify container runtime:**
   ```bash
   docker run --rm hello-world  # or podman
   ```
5. **Create an issue** with output of:
   ```bash
   ./run-x11.sh sh -c "echo 'DISPLAY: $DISPLAY' && uname -a"
   ```

---

*This setup enables cross-platform GUI development using Linux containers on Windows! 🚀*
