#!/bin/bash
#
# build-venv.sh - Python virtual environment CEF build script
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

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check CMake
    if ! command -v cmake &> /dev/null; then
        missing_deps+=("cmake")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Setup virtual environment
setup_venv() {
    local venv_dir="cef-build-env"
    
    log_info "Setting up Python virtual environment..."
    
    if [[ ! -d "$venv_dir" ]]; then
        python3 -m venv "$venv_dir"
    fi
    
    # Activate virtual environment
    source "$venv_dir/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    log_success "Virtual environment ready!"
}

# Build CEF
build_cef() {
    log_info "Starting CEF build in virtual environment..."
    log_warning "This will take 1-3 hours and download several GB of data..."
    
    # Create necessary directories
    mkdir -p builds downloads depot_tools
    
    # Check if CEF source exists
    if [[ ! -d "cef-source" ]]; then
        log_error "CEF source directory not found. Make sure git submodules are initialized."
        log_info "Run: git submodule update --init --recursive"
        exit 1
    fi
    
    # Run CEF build using the submodule
    cd cef-source
    
    # Download depot_tools if not present
    if [[ ! -d "../depot_tools/.git" ]]; then
        log_info "Downloading depot_tools..."
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ../depot_tools
    fi
    
    # Add depot_tools to PATH
    export PATH="$(pwd)/../depot_tools:$PATH"
    
    # Run automate-git.py
    log_info "Running CEF automate build..."
    python3 tools/automate/automate-git.py \
        --download-dir=../downloads \
        --depot-tools-dir=../depot_tools \
        --no-debug-build \
        --client-distrib \
        --sandbox \
        --build-log-file=../builds/build.log \
        --x64-build
    
    cd ..
    
    # Copy build artifacts
    if [[ -d "downloads" ]]; then
        # Find CEF binary directories
        find downloads -name "cef_binary_*" -type d | while read -r cef_dir; do
            if [[ -n "$cef_dir" ]]; then
                log_info "Copying build artifacts from: $cef_dir"
                cp -r "$cef_dir"/* builds/ 2>/dev/null || true
            fi
        done
        
        # Check if we have any artifacts
        if [[ "$(ls -A builds 2>/dev/null)" ]]; then
            log_success "CEF build completed successfully!"
        else
            log_error "Build completed but no artifacts found"
            exit 1
        fi
    else
        log_error "Build failed - downloads directory not found"
        exit 1
    fi
}

# Main function
main() {
    log_info "Starting Python virtual environment CEF build..."
    
    check_dependencies
    setup_venv
    build_cef
    
    log_success "Build process completed!"
    log_info "Build artifacts available in: builds/"
    ls -la builds/ 2>/dev/null || log_warning "No files in builds directory to display"
}

main "$@"
