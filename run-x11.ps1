# Windows PowerShell script for running Fedora GUI container with X11 support
# Equivalent to run-x11.sh for Windows environments

param(
    [string[]]$Command = @()
)

Write-Host "Starting Fedora GUI container with X11 support..." -ForegroundColor Cyan

# Check if DISPLAY is set
if (-not $env:DISPLAY) {
    Write-Host "❌ DISPLAY environment variable is not set" -ForegroundColor Red
    Write-Host "Please run setup-windows.ps1 first or set manually:" -ForegroundColor Yellow
    Write-Host "  `$env:DISPLAY = 'host.docker.internal:0'"
    exit 1
}

Write-Host "🖥️  Detected Windows - configuring for X11 server" -ForegroundColor Green
Write-Host "🔍 DISPLAY: $env:DISPLAY" -ForegroundColor White

# Check if X11 server is running
$x11Port = Get-NetTCPConnection -LocalPort 6000 -ErrorAction SilentlyContinue
if (-not $x11Port) {
    Write-Host "❌ X11 server is not running on port 6000" -ForegroundColor Red
    Write-Host ""
    Write-Host "🚀 Please start your X11 server:" -ForegroundColor Yellow
    Write-Host "   • VcXsrv: Run XLaunch, enable 'Disable access control'"
    Write-Host "   • X410: Launch from Start Menu or Microsoft Store"
    Write-Host "   • Xming: Run with -ac parameter"
    Write-Host "   • MobaXterm: Ensure X server is active"
    Write-Host ""
    Write-Host "🔧 Then run setup-windows.ps1 to verify configuration"
    exit 1
}

Write-Host "✅ X11 server is running on port 6000" -ForegroundColor Green

# Detect container runtime
$containerCmd = ""
$dockerPath = Get-Command "docker.exe" -ErrorAction SilentlyContinue
$podmanPath = Get-Command "podman.exe" -ErrorAction SilentlyContinue

if ($podmanPath) {
    $containerCmd = "podman"
    Write-Host "🐳 Using Podman" -ForegroundColor Green
} elseif ($dockerPath) {
    $containerCmd = "docker" 
    Write-Host "🐳 Using Docker" -ForegroundColor Green
} else {
    Write-Host "❌ No container runtime found (Docker/Podman)" -ForegroundColor Red
    Write-Host "Please install Docker Desktop or Podman for Windows"
    exit 1
}

# Build container command
$containerArgs = @(
    "run", "--rm", "-it"
    "-e", "DISPLAY=$env:DISPLAY"
)

# Add networking based on container runtime
if ($containerCmd -eq "podman") {
    $containerArgs += "--add-host=host.containers.internal:host-gateway"
} else {
    # Docker Desktop handles host.docker.internal automatically
    $containerArgs += "--net=host"
}

# Add the container image
$containerArgs += "fedora_gui"

# Add user command if provided
if ($Command.Count -gt 0) {
    $containerArgs += $Command
}

# Display the command being run
$cmdString = "$containerCmd $($containerArgs -join ' ')"
Write-Host "Running: $cmdString" -ForegroundColor Cyan

# Execute the container
try {
    & $containerCmd $containerArgs
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "✅ Container exited successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Container exited with code: $exitCode" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to run container: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🧹 Cleaning up..." -ForegroundColor Gray
