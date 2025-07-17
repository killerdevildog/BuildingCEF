#!/usr/bin/env python3
"""
build.py - Cross-platform CEF build driver (Pure Python Fallback)
Usage: python build.py

This script provides a pure Python alternative for building CEF
when SCons or CMake are not available or preferred.
"""

import os
import platform
import subprocess
import sys
import datetime
import json
from pathlib import Path

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

def load_config():
    """Load build configuration"""
    config_file = "build-config.json"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            return json.load(f)
    return {}

def detect_os():
    """Detect the host operating system"""
    system = platform.system().lower()
    if system == "linux":
        return "linux"
    elif system == "windows":
        return "windows"
    elif system == "darwin":
        return "macos"
    else:
        raise Exception(f"Unsupported operating system: {system}")

def check_privileges(host_os):
    """Check if running with appropriate privileges"""
    if host_os == "windows":
        try:
            import ctypes
            is_admin = ctypes.windll.shell32.IsUserAnAdmin()
            if not is_admin:
                log_error("Windows builds require Administrator privileges")
                log_info("Please run 'python build.py' from an Administrator PowerShell/Command Prompt")
                return False
        except Exception:
            log_warning("Could not determine if running as Administrator")
    return True

def run_bootstrap_script(host_os):
    """Run bootstrap script to ensure Docker is installed"""
    log_step(1, f"Ensuring Docker is installed on {host_os}")
    
    script_map = {
        "linux": ("./scripts/bootstrap/install-docker.sh", ["/bin/bash"]),
        "windows": (r".\scripts\bootstrap\install-docker.ps1", 
                   ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File"]),
        "macos": ("./scripts/bootstrap/install-docker-macos.sh", ["/bin/bash"])
    }
    
    if host_os not in script_map:
        raise Exception(f"Unsupported OS for bootstrap: {host_os}")
    
    script_path, cmd_prefix = script_map[host_os]
    cmd = cmd_prefix + [script_path]
    
    log_info(f"Running bootstrap script: {script_path}")
    
    try:
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
        
        # Print output for transparency
        if result.stdout:
            print(result.stdout)
        if result.stderr and result.stderr.strip():
            print(result.stderr)
            
        # Handle different exit codes
        if result.returncode == 0:
            log_success("Docker installation verified successfully")
            return True
        elif result.returncode == 3010:  # Windows reboot required
            log_warning("System reboot required to complete Docker installation")
            log_info("Please reboot and run 'python build.py' again")
            return False
        elif result.returncode == 2:  # Manual setup required (macOS)
            log_warning("Manual Docker Desktop setup required")
            log_info("Please complete Docker Desktop setup and run 'python build.py' again")
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

def build_cef_container(host_os):
    """Build CEF container"""
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

def run_cef_container(host_os):
    """Run CEF build container"""
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
            
            # Create completion marker
            marker_file = os.path.join(builds_dir, "cef_build_complete.marker")
            with open(marker_file, 'w') as f:
                f.write(f"CEF build completed successfully at {datetime.datetime.now().isoformat()}\n")
            
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

def print_help():
    """Print help information"""
    print(f"""
{Colors.BOLD}BuildingCEF - Cross-platform CEF build system{Colors.NC}

{Colors.BLUE}Usage:{Colors.NC}
  python build.py         Build CEF for current platform
  python build.py --help  Show this help

{Colors.BLUE}Requirements:{Colors.NC}
  - Windows: Run from Administrator PowerShell/Command Prompt
  - Linux/macOS: Regular user privileges (will prompt for sudo if needed)
  
{Colors.BLUE}Build Process:{Colors.NC}
  1. Detect your operating system (Linux/Windows/macOS)
  2. Install Docker if not already present
  3. Build the appropriate CEF container
  4. Run the CEF build process (1-3 hours)
  5. Output artifacts to builds/ directory

{Colors.BLUE}Examples:{Colors.NC}
  python build.py         # Auto-detect OS and build CEF
  python build.py --help  # Show this help

{Colors.YELLOW}Note:{Colors.NC} This is the pure Python fallback when SCons/CMake are unavailable.
Prefer using 'scons' or 'cmake -B build && cmake --build build' if available.
""")

def main():
    """Main build function"""
    # Check for help flag
    if "--help" in sys.argv or "-h" in sys.argv:
        print_help()
        return 0
    
    log_info("BuildingCEF - Cross-platform CEF build system (Pure Python)")
    log_info("Starting CEF build process...")
    
    # Load configuration
    config = load_config()
    if config:
        log_info(f"Using CEF version: {config.get('cef_version', 'latest')}")
        log_info(f"Build type: {config.get('build_type', 'Release')}")
    
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
        
    except KeyboardInterrupt:
        log_warning("Build process interrupted by user")
        return 130
    except Exception as e:
        log_error(f"Build process failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
