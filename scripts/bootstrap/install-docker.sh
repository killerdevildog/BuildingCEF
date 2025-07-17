#!/bin/bash
#
# install-docker.sh - Cross-platform Docker Engine installer for Linux
# Supports Ubuntu/Debian, RHEL/Fedora/CentOS, and Arch Linux
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    log_info "Detected distribution: $DISTRO $VERSION"
}

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null || echo "unknown")
        log_warning "Docker is already installed: $DOCKER_VERSION"
        
        # Check if docker service is running
        if systemctl is-active --quiet docker; then
            log_info "Docker service is already running"
        else
            log_info "Starting Docker service..."
            sudo systemctl enable docker
            sudo systemctl start docker
        fi
        
        # Check if user is in docker group
        if groups $USER | grep -q docker; then
            log_info "User $USER is already in docker group"
            return 0
        else
            log_info "Adding user $USER to docker group..."
            sudo usermod -aG docker $USER
            log_warning "Please log out and log back in, or run 'newgrp docker' to apply group changes"
        fi
        return 0
    fi
    return 1
}

# Install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    log_info "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Use Docker's convenience script
    log_info "Downloading and running Docker installation script..."
    curl -fsSL https://get.docker.com | sudo -E bash -
    
    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully on Ubuntu/Debian"
}

# Install Docker on RHEL/Fedora/CentOS
install_docker_rhel() {
    log_info "Installing Docker on RHEL/Fedora/CentOS..."
    
    # Detect package manager
    if command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
    elif command -v yum &> /dev/null; then
        PKG_MGR="yum"
    else
        log_error "No suitable package manager found (dnf/yum)"
        exit 1
    fi
    
    # Use Docker's convenience script
    log_info "Downloading and running Docker installation script..."
    curl -fsSL https://get.docker.com | sudo -E bash -
    
    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully on RHEL/Fedora/CentOS"
}

# Install Docker on Arch Linux
install_docker_arch() {
    log_info "Installing Docker on Arch Linux..."
    
    # Update package database
    sudo pacman -Sy
    
    # Install Docker
    sudo pacman -S --noconfirm docker
    
    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully on Arch Linux"
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
    
    # Test Docker with hello-world (may need newgrp if user just added to group)
    log_info "Testing Docker with hello-world container..."
    if docker run --rm hello-world &> /dev/null; then
        log_success "Docker hello-world test passed"
    else
        log_warning "Docker hello-world test failed. You may need to run 'newgrp docker' or log out/in."
        log_info "Try running: newgrp docker"
        return 1
    fi
}

# Main installation function
main() {
    log_info "Starting Docker installation for Linux..."
    
    check_root
    detect_distro
    
    if check_docker_installed; then
        verify_docker
        return $?
    fi
    
    case $DISTRO in
        ubuntu|debian)
            install_docker_ubuntu
            ;;
        rhel|fedora|centos|rocky|almalinux)
            install_docker_rhel
            ;;
        arch|manjaro)
            install_docker_arch
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            log_info "Please install Docker manually from https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    log_warning "Please log out and log back in, or run 'newgrp docker' to apply group changes"
    log_info "After that, you can verify the installation by running: docker run --rm hello-world"
    
    log_success "Docker installation completed successfully!"
    log_info "You can now build CEF containers using the provided Dockerfiles"
}

# Run main function
main "$@"
