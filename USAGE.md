# BuildingCEF Usage Guide

## Quick Start

1. **Validate Setup** (recommended first step):
   ```bash
   python3 test-setup.py
   ```

2. **One-Command Build**:
   ```bash
   # Option 1: SCons (preferred)
   scons
   
   # Option 2: CMake (fallback)
   cmake -B build && cmake --build build
   
   # Option 3: Pure Python (universal)
   python3 build.py
   ```

## Prerequisites Validation

Run the comprehensive environment check:
```bash
python3 scripts/setup-environment.py
```

This validates:
- Python 3.8+ compatibility
- Git availability
- Docker installation
- Platform-specific build tools
- Disk space (20GB+ recommended)
- Memory (8GB+ recommended)
- Configuration file validity
- CEF submodule status

## Manual Docker Build

If you prefer manual control:

```bash
# Linux
docker build -t cef-builder-linux -f Dockerfile.linux .
docker run --rm -v $PWD/builds:/workspace/builds cef-builder-linux

# Windows (from Administrator PowerShell)
docker build -t cef-builder-windows -f Dockerfile.windows .
docker run --rm -v %cd%/builds:C:/workspace/builds cef-builder-windows

# macOS
docker build -t cef-builder-macos -f Dockerfile.macos .
docker run --rm -v $PWD/builds:/workspace/builds cef-builder-macos
```

## Python Virtual Environment Build

For environments without Docker:

```bash
# Setup
python3 -m venv cef-build-env
source cef-build-env/bin/activate  # Linux/macOS
# or
cef-build-env\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Build
./scripts/build-venv.sh
```

## Configuration

Edit `build-config.json` to customize:

```json
{
  "cef_version": "127.3.5",
  "target_platform": "linux64",
  "build_type": "Release",
  "python_version": "3.8",
  "chromium_branch": "6045",
  "custom_flags": [
    "--no-debug-build",
    "--client-distrib",
    "--sandbox"
  ]
}
```

## Updating CEF Version

```bash
# Check for updates
python3 scripts/update-cef.py

# Auto-update without prompts
python3 scripts/update-cef.py --auto
```

## Troubleshooting

1. **Permission Errors** (Linux/macOS):
   ```bash
   sudo chmod +x scripts/*.sh scripts/*.py
   ```

2. **Windows Admin Required**:
   - Right-click PowerShell → "Run as Administrator"

3. **Submodule Issues**:
   ```bash
   git submodule update --init --recursive
   ```

4. **Docker Issues**:
   ```bash
   # Run bootstrap scripts
   ./scripts/bootstrap/install-docker.sh        # Linux
   .\scripts\bootstrap\install-docker.ps1       # Windows
   ./scripts/bootstrap/install-docker-macos.sh  # macOS
   ```

5. **Clean Build**:
   ```bash
   scons clean           # SCons
   rm -rf builds/ cache/ # Manual
   ```

## Build Output

Successful builds create:
- `builds/` - CEF binaries and libraries
- `builds/cef_build_complete.marker` - Build completion marker
- `builds/build.log` - Build log (venv builds)

## Expected Build Time

- **First build**: 2-4 hours (downloads Chromium source)
- **Incremental builds**: 30-60 minutes
- **Hardware impact**: 
  - Fast with SSD + 16GB+ RAM + 8+ cores
  - Slower with HDD + 8GB RAM + 4 cores

## Requirements Summary

### Minimum:
- **OS**: Linux, Windows 10+, macOS 11+
- **RAM**: 8GB (16GB recommended)
- **Disk**: 20GB free space (50GB recommended)
- **Network**: Stable broadband (downloads 10-15GB)

### Software:
- **Docker**: Automatically installed by bootstrap scripts
- **Python**: 3.8+ (included in most modern systems)
- **Git**: For submodule management

### Windows Specific:
- Administrator privileges required
- Visual Studio Build Tools 2022 (installed by Docker)

### Linux Specific:
- build-essential package
- CMake 3.19+

### macOS Specific:
- Xcode Command Line Tools
- Homebrew (for Docker Desktop)

## Platform Support Matrix

| Platform | Docker | Venv | Status | Notes |
|----------|--------|------|--------|-------|
| Ubuntu 20.04+ | ✅ | ✅ | Stable | Recommended |
| Debian 11+ | ✅ | ✅ | Stable | Well tested |
| RHEL/CentOS 8+ | ✅ | ✅ | Stable | Enterprise ready |
| Fedora 35+ | ✅ | ✅ | Stable | Latest features |
| Arch Linux | ✅ | ✅ | Stable | Rolling release |
| Windows 10 2004+ | ✅ | ✅ | Stable | Requires admin |
| Windows 11 | ✅ | ✅ | Stable | Optimal |
| macOS 11+ (Intel) | ✅ | ✅ | Beta | Cross-compile |
| macOS 11+ (Apple Silicon) | ✅ | ❌ | Planned | Future support |

This repository provides the most comprehensive and automated CEF build system available, supporting all major platforms with multiple build methods for maximum compatibility.
