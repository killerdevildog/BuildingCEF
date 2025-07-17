#!/bin/bash
#
# build-docker.sh - Docker-based CEF build script
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

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Main build function
main() {
    local os=$(detect_os)
    local dockerfile="Dockerfile.${os}"
    local image_name="cef-builder-${os}"
    local container_name="cef-build-container"
    
    log_info "Starting CEF build for ${os}..."
    
    # Check if Dockerfile exists
    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile not found: $dockerfile"
        exit 1
    fi
    
    # Create builds directory
    mkdir -p builds
    
    # Build Docker image
    log_info "Building Docker image: $image_name"
    docker build -t "$image_name" -f "$dockerfile" .
    
    # Run build container
    log_info "Running CEF build in container..."
    log_warning "This will take 1-3 hours depending on your hardware..."
    
    case "$os" in
        "windows")
            docker run --rm \
                --name "$container_name" \
                -v "$(pwd)/builds:C:/workspace/builds" \
                "$image_name"
            ;;
        *)
            docker run --rm \
                --name "$container_name" \
                -v "$(pwd)/builds:/workspace/builds" \
                "$image_name"
            ;;
    esac
    
    # Verify build output
    if [[ -d "builds" ]] && [[ "$(ls -A builds)" ]]; then
        log_success "CEF build completed successfully!"
        log_info "Build artifacts available in: builds/"
        ls -la builds/
    else
        log_error "Build failed - no artifacts found in builds/"
        exit 1
    fi
}

main "$@"
