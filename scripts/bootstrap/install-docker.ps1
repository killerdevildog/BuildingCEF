#
# install-docker.ps1 - Docker Desktop installer for Windows
# Requires Windows 10/11 and Administrator privileges
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"

# Logging functions
function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $BLUE
}

function Log-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $GREEN
}

function Log-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $YELLOW
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $RED
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check Windows version
function Test-WindowsVersion {
    $version = [System.Environment]::OSVersion.Version
    $buildNumber = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    Log-Info "Windows Version: $($version.Major).$($version.Minor) Build $buildNumber"
    
    # Check for Windows 10 (build 19041+) or Windows 11
    if (($version.Major -eq 10 -and [int]$buildNumber -ge 19041) -or $version.Major -gt 10) {
        return $true
    }
    else {
        Log-Error "Docker Desktop requires Windows 10 version 2004 (build 19041) or later, or Windows 11"
        return $false
    }
}

# Check if Docker is already installed
function Test-DockerInstalled {
    try {
        $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
        if ($dockerPath) {
            $dockerVersion = docker --version 2>$null
            Log-Warning "Docker is already installed: $dockerVersion"
            
            # Check if Docker Desktop is running
            $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
            if ($dockerProcess) {
                Log-Info "Docker Desktop is already running"
            }
            else {
                Log-Info "Starting Docker Desktop..."
                Start-Process -FilePath "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
                Start-Sleep -Seconds 10
            }
            return $true
        }
    }
    catch {
        # Docker not found, continue with installation
    }
    return $false
}

# Check if WSL2 is available
function Test-WSL2 {
    try {
        $wslVersion = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Log-Info "WSL2 is available"
            return $true
        }
    }
    catch {
        Log-Warning "WSL2 is not available. Docker Desktop will use Hyper-V backend."
    }
    return $false
}

# Enable required Windows features
function Enable-RequiredFeatures {
    Log-Info "Checking and enabling required Windows features..."
    
    $features = @("Microsoft-Hyper-V-All", "VirtualMachinePlatform")
    $rebootRequired = $false
    
    foreach ($feature in $features) {
        $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
        if ($featureState -and $featureState.State -ne "Enabled") {
            Log-Info "Enabling feature: $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
            $rebootRequired = $true
        }
        elseif ($featureState) {
            Log-Info "Feature already enabled: $feature"
        }
    }
    
    return $rebootRequired
}

# Download Docker Desktop installer
function Get-DockerInstaller {
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
    
    Log-Info "Downloading Docker Desktop installer..."
    
    try {
        # Use Invoke-WebRequest with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (Test-Path $installerPath) {
            $fileSize = (Get-Item $installerPath).Length / 1MB
            Log-Success "Downloaded Docker Desktop installer ($([math]::Round($fileSize, 2)) MB)"
            return $installerPath
        }
        else {
            throw "Download failed"
        }
    }
    catch {
        Log-Error "Failed to download Docker Desktop installer: $($_.Exception.Message)"
        throw
    }
}

# Install Docker Desktop
function Install-DockerDesktop {
    param([string]$InstallerPath)
    
    Log-Info "Installing Docker Desktop (this may take several minutes)..."
    
    try {
        # Run installer with quiet mode
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Log-Success "Docker Desktop installation completed successfully"
        }
        elseif ($process.ExitCode -eq 3010) {
            Log-Warning "Docker Desktop installation completed but requires a reboot"
            return $true  # Reboot required
        }
        else {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        Log-Error "Failed to install Docker Desktop: $($_.Exception.Message)"
        throw
    }
    finally {
        # Clean up installer
        if (Test-Path $InstallerPath) {
            Remove-Item $InstallerPath -Force
        }
    }
    
    return $false  # No reboot required
}

# Verify Docker installation
function Test-DockerInstallation {
    Log-Info "Verifying Docker installation..."
    
    # Wait for Docker Desktop to start
    $timeout = 60  # seconds
    $elapsed = 0
    
    Log-Info "Waiting for Docker Desktop to start..."
    while ($elapsed -lt $timeout) {
        try {
            $version = docker --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Log-Success "Docker version: $version"
                break
            }
        }
        catch {
            # Continue waiting
        }
        
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host "." -NoNewline
    }
    
    if ($elapsed -ge $timeout) {
        Log-Warning "Docker Desktop took longer than expected to start"
        Log-Info "Please manually start Docker Desktop and verify the installation"
        return
    }
    
    # Test Docker with hello-world
    Log-Info "Testing Docker with hello-world container..."
    try {
        docker run --rm hello-world | Out-Null
        Log-Success "Docker hello-world test passed"
    }
    catch {
        Log-Warning "Docker hello-world test failed. Docker Desktop may still be starting up."
        Log-Info "Please wait a moment and try running: docker run --rm hello-world"
    }
}

# Main function
function Main {
    Log-Info "Starting Docker Desktop installation for Windows..."
    
    # Check prerequisites
    if (-not (Test-Administrator)) {
        Log-Error "This script must be run as Administrator"
        Log-Info "Please right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    if (-not (Test-WindowsVersion)) {
        exit 1
    }
    
    # Check if already installed
    if (Test-DockerInstalled) {
        Test-DockerInstallation
        return
    }
    
    # Check WSL2 availability
    Test-WSL2 | Out-Null
    
    # Enable required features
    $featuresRebootRequired = Enable-RequiredFeatures
    
    if ($featuresRebootRequired) {
        Log-Warning "Windows features have been enabled but require a reboot"
        Log-Info "Please reboot your system and run this script again to complete Docker installation"
        exit 3010
    }
    
    # Download and install Docker Desktop
    try {
        $installerPath = Get-DockerInstaller
        $installRebootRequired = Install-DockerDesktop -InstallerPath $installerPath
        
        if ($installRebootRequired) {
            Log-Warning "Docker Desktop installation requires a reboot"
            Log-Info "Please reboot your system to complete the installation"
            exit 3010
        }
        
        # Start Docker Desktop
        Log-Info "Starting Docker Desktop..."
        Start-Process -FilePath "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
        
        # Verify installation
        Test-DockerInstallation
        
        Log-Success "Docker Desktop installation completed successfully!"
        Log-Info "You can now build CEF containers using the provided Dockerfiles"
    }
    catch {
        Log-Error "Installation failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run main function
Main
