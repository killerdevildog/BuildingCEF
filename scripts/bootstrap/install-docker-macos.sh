#!/bin/bash
#
# install-docker-macos.sh - Docker Desktop installer for macOS
# Supports macOS 11 (Big Sur) and later
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    
    log_info "macOS Version: $version"
    
    # Check for macOS 11 or later
    if [[ $major -ge 11 ]] || [[ $major -eq 10 && $minor -ge 15 ]]; then
        return 0
    else
        log_error "Docker Desktop requires macOS 11 (Big Sur) or later"
        log_info "Current version: $version"
        return 1
    fi
}

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null || echo "unknown")
        log_warning "Docker is already installed: $docker_version"
        
        # Check if Docker Desktop is running
        if pgrep -f "Docker Desktop" > /dev/null; then
            log_info "Docker Desktop is already running"
        else
            log_info "Starting Docker Desktop..."
            open -a "Docker Desktop" || log_warning "Could not start Docker Desktop automatically"
        fi
        return 0
    fi
    return 1
}

# Check if Homebrew is installed
check_homebrew() {
    if command -v brew &> /dev/null; then
        log_info "Homebrew is already installed"
        return 0
    else
        log_info "Homebrew not found. Installing Homebrew..."
        return 1
    fi
}

# Install Homebrew
install_homebrew() {
    log_info "Installing Homebrew..."
    
    # Download and run Homebrew installation script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        export PATH="/opt/homebrew/bin:$PATH"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        export PATH="/usr/local/bin:$PATH"
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Verify Homebrew installation
    if command -v brew &> /dev/null; then
        log_success "Homebrew installed successfully"
        return 0
    else
        log_error "Homebrew installation failed"
        return 1
    fi
}

# Install Docker Desktop via Homebrew
install_docker_desktop() {
    log_info "Installing Docker Desktop via Homebrew..."
    
    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update
    
    # Install Docker Desktop
    log_info "Installing Docker Desktop (this may take several minutes)..."
    brew install --cask docker
    
    log_success "Docker Desktop installed successfully"
}

# Configure Docker Desktop to start on login
configure_docker_autostart() {
    log_info "Configuring Docker Desktop to start automatically..."
    
    local docker_app_path="/Applications/Docker.app"
    local plist_name="com.docker.docker"
    local plist_path="$HOME/Library/LaunchAgents/${plist_name}.plist"
    
    if [[ -d "$docker_app_path" ]]; then
        # Create LaunchAgent plist for auto-start
        cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>Docker</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
        
        # Load the LaunchAgent
        launchctl load "$plist_path" 2>/dev/null || true
        
        log_success "Docker Desktop configured to start on login"
    else
        log_warning "Docker.app not found at expected location: $docker_app_path"
    fi
}

# Start Docker Desktop
start_docker_desktop() {
    log_info "Starting Docker Desktop..."
    
    # Try to open Docker Desktop
    if open -a "Docker Desktop" 2>/dev/null || open -a "Docker" 2>/dev/null; then
        log_info "Docker Desktop is starting..."
        
        # Wait for Docker Desktop to start
        local timeout=60
        local elapsed=0
        
        log_info "Waiting for Docker Desktop to become ready..."
        while [[ $elapsed -lt $timeout ]]; do
            if docker system info &> /dev/null; then
                log_success "Docker Desktop is ready"
                return 0
            fi
            
            sleep 3
            elapsed=$((elapsed + 3))
            echo -n "."
        done
        
        echo  # New line after dots
        log_warning "Docker Desktop is taking longer than expected to start"
        log_info "Please manually open Docker Desktop from Applications and complete the setup"
        return 1
    else
        log_error "Could not start Docker Desktop automatically"
        log_info "Please manually open Docker Desktop from Applications"
        return 1
    fi
}

# Verify Docker installation
verify_docker() {
    log_info "Verifying Docker installation..."
    
    # Check Docker version
    if docker --version; then
        log_success "Docker version check passed"
    else
        log_error "Docker version check failed"
        return 1
    fi
    
    # Test Docker with hello-world
    log_info "Testing Docker with hello-world container..."
    if docker run --rm hello-world &> /dev/null; then
        log_success "Docker hello-world test passed"
    else
        log_warning "Docker hello-world test failed. Docker Desktop may still be starting up."
        log_info "Please wait a moment and try running: docker run --rm hello-world"
        return 1
    fi
    
    return 0
}

# Main installation function
main() {
    log_info "Starting Docker Desktop installation for macOS..."
    
    check_macos
    
    if ! check_macos_version; then
        exit 1
    fi
    
    if check_docker_installed; then
        if verify_docker; then
            return 0
        fi
    fi
    
    # Install Homebrew if needed
    if ! check_homebrew; then
        if ! install_homebrew; then
            log_error "Failed to install Homebrew"
            exit 1
        fi
    fi
    
    # Install Docker Desktop
    install_docker_desktop
    
    # Configure auto-start
    configure_docker_autostart
    
    # Start Docker Desktop
    if ! start_docker_desktop; then
        log_warning "Docker Desktop needs to be started manually"
        log_info "Please:"
        log_info "1. Open Applications folder"
        log_info "2. Double-click Docker to start Docker Desktop"
        log_info "3. Complete the initial setup when prompted"
        log_info "4. Run 'docker run --rm hello-world' to verify the installation"
        exit 2
    fi
    
    # Verify installation
    if verify_docker; then
        log_success "Docker Desktop installation completed successfully!"
        log_info "You can now build CEF containers using the provided Dockerfiles"
    else
        log_warning "Docker Desktop was installed but verification failed"
        log_info "Please complete the Docker Desktop setup manually and try running: docker run --rm hello-world"
    fi
}

# Run main function
main "$@"
