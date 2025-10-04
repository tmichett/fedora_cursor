# Windows Setup Script for Fedora GUI Container with X11 Support
# PowerShell script to configure X11 server for container GUI forwarding

Write-Host "🖥️ Windows X11 Setup for Container GUI Forwarding" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Check if running on Windows
if ($env:OS -ne "Windows_NT") {
    Write-Host "❌ This script is only for Windows systems" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Windows system detected" -ForegroundColor Green

# Check for X11 servers
$x11Servers = @()
$vcxsrvPath = Get-Command "vcxsrv.exe" -ErrorAction SilentlyContinue
$x410Process = Get-Process "X410" -ErrorAction SilentlyContinue
$xmingPath = Get-Command "Xming.exe" -ErrorAction SilentlyContinue
$mobaxPath = Get-Command "MobaXterm.exe" -ErrorAction SilentlyContinue

if ($vcxsrvPath) { $x11Servers += "VcXsrv" }
if ($x410Process) { $x11Servers += "X410" }
if ($xmingPath) { $x11Servers += "Xming" }
if ($mobaxPath) { $x11Servers += "MobaXterm" }

if ($x11Servers.Count -eq 0) {
    Write-Host "❌ No X11 server found" -ForegroundColor Red
    Write-Host ""
    Write-Host "📥 Please install an X11 server:" -ForegroundColor Yellow
    Write-Host "   • VcXsrv (Recommended): https://sourceforge.net/projects/vcxsrv/"
    Write-Host "   • X410: https://apps.microsoft.com/store/detail/x410/9NLP712ZMN9Q"
    Write-Host "   • Xming: https://sourceforge.net/projects/xming/"
    Write-Host "   • MobaXterm: https://mobaxterm.mobatek.net/"
    Write-Host ""
    Write-Host "🔧 For VcXsrv (easiest option):" -ForegroundColor Cyan
    Write-Host "   1. Download and install VcXsrv"
    Write-Host "   2. Run XLaunch from Start Menu"
    Write-Host "   3. Choose 'Multiple windows', click Next"
    Write-Host "   4. Choose 'Start no client', click Next"  
    Write-Host "   5. ✅ Check 'Disable access control'"
    Write-Host "   6. Click 'Finish'"
    exit 1
}

Write-Host "✅ Found X11 server(s): $($x11Servers -join ', ')" -ForegroundColor Green

# Check if X11 server is running and listening on port 6000
$x11Port = Get-NetTCPConnection -LocalPort 6000 -ErrorAction SilentlyContinue
if ($x11Port) {
    Write-Host "✅ X11 server is running on port 6000" -ForegroundColor Green
} else {
    Write-Host "⚠️  X11 server is not running on port 6000" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🚀 Please start your X11 server:" -ForegroundColor Cyan
    
    if ($x11Servers -contains "VcXsrv") {
        Write-Host "   For VcXsrv: Run 'XLaunch' from Start Menu" -ForegroundColor White
        Write-Host "   • Multiple windows → Start no client → ✅ Disable access control"
    }
    if ($x11Servers -contains "X410") {
        Write-Host "   For X410: Launch X410 from Start Menu or Store" -ForegroundColor White
    }
    if ($x11Servers -contains "Xming") {
        Write-Host "   For Xming: Run Xming with '-ac' parameter (disable access control)" -ForegroundColor White
    }
    if ($x11Servers -contains "MobaXterm") {
        Write-Host "   For MobaXterm: Start MobaXterm and ensure X11 server is running" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🔧 Important: Make sure 'Disable access control' is enabled!" -ForegroundColor Red
    Write-Host "   This allows containers to connect to the X11 server."
    exit 1
}

# Check container runtime
$containerRuntime = ""
$dockerPath = Get-Command "docker.exe" -ErrorAction SilentlyContinue
$podmanPath = Get-Command "podman.exe" -ErrorAction SilentlyContinue

if ($dockerPath) { 
    $containerRuntime = "docker"
    Write-Host "✅ Docker found: $($dockerPath.Source)" -ForegroundColor Green
}
if ($podmanPath) { 
    $containerRuntime = "podman"  
    Write-Host "✅ Podman found: $($podmanPath.Source)" -ForegroundColor Green
}

if (-not $containerRuntime) {
    Write-Host "❌ No container runtime found" -ForegroundColor Red
    Write-Host ""
    Write-Host "📥 Please install a container runtime:" -ForegroundColor Yellow
    Write-Host "   • Docker Desktop: https://www.docker.com/products/docker-desktop/"
    Write-Host "   • Podman: https://podman.io/getting-started/installation#windows"
    exit 1
}

# Set DISPLAY environment variable
$displayVar = "host.docker.internal:0"
if ($containerRuntime -eq "podman") {
    $displayVar = "host.containers.internal:0"
}

Write-Host ""
Write-Host "🔧 Setting up environment..." -ForegroundColor Cyan
Write-Host "Setting DISPLAY=$displayVar" -ForegroundColor White

# Set for current session
$env:DISPLAY = $displayVar

# Set persistently for user
[System.Environment]::SetEnvironmentVariable("DISPLAY", $displayVar, [System.EnvironmentVariableTarget]::User)

Write-Host "✅ DISPLAY variable set" -ForegroundColor Green

# Test X11 connection
Write-Host ""
Write-Host "🔍 Testing X11 connection..." -ForegroundColor Cyan

try {
    $testResult = Test-NetConnection -ComputerName "localhost" -Port 6000 -WarningAction SilentlyContinue
    if ($testResult.TcpTestSucceeded) {
        Write-Host "✅ X11 server is accessible on localhost:6000" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot connect to X11 server on port 6000" -ForegroundColor Red
        Write-Host "   Make sure your X11 server is running and configured correctly" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not test X11 connection" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "✅ X11 server detected and configured" -ForegroundColor White
Write-Host "✅ Container runtime available ($containerRuntime)" -ForegroundColor White
Write-Host "✅ DISPLAY variable set to: $displayVar" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Ensure X11 server is running with 'Disable access control' enabled"
Write-Host "2. Build your container: .\build.ps1 (or bash build.sh)"
Write-Host "3. Test GUI forwarding: .\run-x11.ps1 (or bash run-x11.sh)"
Write-Host ""
Write-Host "🔧 Container Commands:" -ForegroundColor Cyan
if ($containerRuntime -eq "docker") {
    Write-Host "docker run --rm -it -e DISPLAY=$displayVar -v /tmp/.X11-unix:/tmp/.X11-unix fedora_gui"
} else {
    Write-Host "podman run --rm -it -e DISPLAY=$displayVar --add-host=host.containers.internal:host-gateway fedora_gui"
}
Write-Host ""
Write-Host "⚠️  Security Note:" -ForegroundColor Yellow
Write-Host "This setup disables X11 access control for container connectivity."
Write-Host "Only use on trusted networks."
