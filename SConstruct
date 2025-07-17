#!/usr/bin/env python3
#
# SConstruct - Cross-platform CEF build driver
# Usage: scons (builds CEF for current platform)
#

import os
import platform
import subprocess
import sys
from pathlib import Path

# SCons environment
env = Environment()

# Colors for terminal output
class Colors:
    if sys.platform != "win32" and hasattr(sys.stdout, 'isatty') and sys.stdout.isatty():
        RED = '\033[0;31m'
        GREEN = '\033[0;32m'
        YELLOW = '\033[1;33m'
        BLUE = '\033[0;34m'
        BOLD = '\033[1m'
        NC = '\033[0m'  # No Color
    else:
        RED = GREEN = YELLOW = BLUE = BOLD = NC = ''

def log_info(message):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {message}")

def log_success(message):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {message}")

def log_warning(message):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")

def log_error(message):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")

def log_step(step, message):
    print(f"{Colors.BOLD}[STEP {step}]{Colors.NC} {message}")

# Detect host operating system
def detect_os():
    system = platform.system().lower()
    if system == "linux":
        return "linux"
    elif system == "windows":
        return "windows"
    elif system == "darwin":
        return "macos"
    else:
        raise Exception(f"Unsupported operating system: {system}")

# Check if running with appropriate privileges
def check_privileges(host_os):
    if host_os == "windows":
        import ctypes
        try:
            is_admin = ctypes.windll.shell32.IsUserAnAdmin()
            if not is_admin:
                log_error("Windows builds require Administrator privileges")
                log_info("Please run 'scons' from an Administrator PowerShell/Command Prompt")
                return False
        except:
            log_warning("Could not determine if running as Administrator")
    return True

# Run bootstrap script to ensure Docker is installed
def run_bootstrap_script(host_os):
    log_step(1, f"Ensuring Docker is installed on {host_os}")
    
    if host_os == "linux":
        script_path = "./scripts/bootstrap/install-docker.sh"
        cmd = ["/bin/bash", script_path]
    elif host_os == "windows":
        script_path = r".\scripts\bootstrap\install-docker.ps1"
        cmd = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
    elif host_os == "macos":
        script_path = "./scripts/bootstrap/install-docker-macos.sh"
        cmd = ["/bin/bash", script_path]
    else:
        raise Exception(f"Unsupported OS for bootstrap: {host_os}")
    
    log_info(f"Running bootstrap script: {script_path}")
    
    try:
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
        
        # Print output for transparency
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)
            
        # Handle different exit codes
        if result.returncode == 0:
            log_success("Docker installation verified successfully")
            return True
        elif result.returncode == 3010:  # Windows reboot required
            log_warning("System reboot required to complete Docker installation")
            log_info("Please reboot and run 'scons' again")
            return False
        elif result.returncode == 2:  # Manual setup required (macOS)
            log_warning("Manual Docker Desktop setup required")
            log_info("Please complete Docker Desktop setup and run 'scons' again")
            return False
        else:
            log_error(f"Bootstrap script failed with exit code {result.returncode}")
            return False
            
    except FileNotFoundError:
        log_error(f"Bootstrap script not found: {script_path}")
        return False
    except Exception as e:
        log_error(f"Failed to run bootstrap script: {e}")
        return False

# Build CEF container
def build_cef_container(host_os):
    log_step(2, f"Building CEF container for {host_os}")
    
    dockerfile_map = {
        "linux": "Dockerfile.linux",
        "windows": "Dockerfile.windows", 
        "macos": "Dockerfile.macos"
    }
    
    dockerfile = dockerfile_map[host_os]
    image_tag = f"cef-builder-{host_os}"
    
    log_info(f"Building Docker image: {image_tag}")
    log_info(f"Using Dockerfile: {dockerfile}")
    
    build_cmd = [
        "docker", "build",
        "-t", image_tag,
        "-f", dockerfile,
        "."
    ]
    
    try:
        log_info("Running: " + " ".join(build_cmd))
        result = subprocess.run(build_cmd, check=False)
        
        if result.returncode == 0:
            log_success(f"Successfully built {image_tag}")
            return True
        else:
            log_error(f"Docker build failed with exit code {result.returncode}")
            return False
            
    except FileNotFoundError:
        log_error("Docker command not found. Please ensure Docker is installed and in PATH")
        return False
    except Exception as e:
        log_error(f"Failed to build container: {e}")
        return False

# Run CEF build container
def run_cef_container(host_os):
    log_step(3, f"Running CEF build container for {host_os}")
    
    image_tag = f"cef-builder-{host_os}"
    builds_dir = os.path.abspath("builds")
    
    # Create builds directory if it doesn't exist
    os.makedirs(builds_dir, exist_ok=True)
    
    # Platform-specific volume mounting
    if host_os == "windows":
        # Windows container expects C:\workspace\builds
        volume_mount = f"{builds_dir}:C:\\workspace\\builds"
    else:
        # Linux/macOS containers expect /workspace/builds
        volume_mount = f"{builds_dir}:/workspace/builds"
    
    run_cmd = [
        "docker", "run",
        "--rm",
        "-v", volume_mount,
        image_tag
    ]
    
    try:
        log_info("Running: " + " ".join(run_cmd))
        log_info(f"Output directory: {builds_dir}")
        log_warning("This will take a significant amount of time (1-3 hours depending on hardware)")
        
        result = subprocess.run(run_cmd, check=False)
        
        if result.returncode == 0:
            log_success("CEF build completed successfully")
            log_info(f"Build artifacts available in: {builds_dir}")
            return True
        else:
            log_error(f"CEF build failed with exit code {result.returncode}")
            return False
            
    except FileNotFoundError:
        log_error("Docker command not found. Please ensure Docker is installed and in PATH")
        return False
    except Exception as e:
        log_error(f"Failed to run container: {e}")
        return False

# Main build function
def build_cef_action(target, source, env):
    """SCons action function for building CEF"""
    
    log_info("Starting cross-platform CEF build process")
    
    try:
        # Detect operating system
        host_os = detect_os()
        log_info(f"Detected operating system: {host_os}")
        
        # Check privileges
        if not check_privileges(host_os):
            return 1
        
        # Step 1: Bootstrap Docker installation
        if not run_bootstrap_script(host_os):
            log_error("Docker bootstrap failed")
            return 1
        
        # Step 2: Build CEF container
        if not build_cef_container(host_os):
            log_error("Container build failed")
            return 1
        
        # Step 3: Run CEF build
        if not run_cef_container(host_os):
            log_error("CEF build failed")
            return 1
        
        log_success("CEF build process completed successfully!")
        log_info("Your CEF build artifacts are ready in the 'builds/' directory")
        return 0
        
    except Exception as e:
        log_error(f"Build process failed: {e}")
        return 1

# Create the build target
cef_build_target = env.Command(
    target=['builds/cef_build_complete.marker'],
    source=[
        'SConstruct',
        'Dockerfile.linux',
        'Dockerfile.windows', 
        'Dockerfile.macos',
        'scripts/bootstrap/install-docker.sh',
        'scripts/bootstrap/install-docker.ps1',
        'scripts/bootstrap/install-docker-macos.sh'
    ],
    action=build_cef_action
)

# Create marker file action
def create_marker_action(target, source, env):
    """Create a marker file to indicate successful build"""
    marker_file = str(target[0])
    os.makedirs(os.path.dirname(marker_file), exist_ok=True)
    with open(marker_file, 'w') as f:
        f.write(f"CEF build completed successfully at {env.get('BUILD_TIMESTAMP', 'unknown time')}\n")
    return 0

# Set build timestamp
import datetime
env['BUILD_TIMESTAMP'] = datetime.datetime.now().isoformat()

# Add alias for convenience
env.Alias('cef-build', cef_build_target)
env.Alias('build', cef_build_target)
env.Alias('all', cef_build_target)

# Set default target
Default('cef-build')

# Help text
Help("""
BuildingCEF - Cross-platform CEF build system

Targets:
  cef-build (default) : Build CEF for the current platform
  build               : Alias for cef-build  
  all                 : Alias for cef-build

Usage:
  scons               : Build CEF for current platform (auto-detects OS)
  scons cef-build     : Explicit build target
  scons -c            : Clean build artifacts
  scons -h            : Show this help

Requirements:
  - Windows: Run from Administrator PowerShell/Command Prompt
  - Linux/macOS: Regular user privileges (will prompt for sudo if needed)
  
The build process will:
  1. Detect your operating system (Linux/Windows/macOS)
  2. Install Docker if not already present
  3. Build the appropriate CEF container
  4. Run the CEF build process
  5. Output artifacts to builds/ directory

Build time: 1-3 hours depending on hardware
""")

# Clean target
env.Clean(cef_build_target, ['builds/'])

# Print startup message
if not env.GetOption('help') and not env.GetOption('clean'):
    log_info("BuildingCEF - Cross-platform CEF build system")
    log_info("Run 'scons -h' for help and usage information")
