#!/usr/bin/env python3
"""
setup-environment.py - Environment setup and validation script
"""

import os
import sys
import platform
import subprocess
import json
from pathlib import Path

def log_info(message):
    print(f"[INFO] {message}")

def log_success(message):
    print(f"[SUCCESS] {message}")

def log_warning(message):
    print(f"[WARNING] {message}")

def log_error(message):
    print(f"[ERROR] {message}")

def check_python_version():
    """Check Python version compatibility"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        log_error(f"Python 3.8+ required, found {version.major}.{version.minor}")
        return False
    log_success(f"Python {version.major}.{version.minor}.{version.micro} OK")
    return True

def check_git():
    """Check Git availability"""
    try:
        result = subprocess.run(['git', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            log_success(f"Git available: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    log_error("Git not found - required for CEF builds")
    return False

def check_docker():
    """Check Docker availability"""
    try:
        result = subprocess.run(['docker', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            log_success(f"Docker available: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    log_warning("Docker not found - will be installed by bootstrap scripts")
    return False

def check_build_tools():
    """Check platform-specific build tools"""
    system = platform.system().lower()
    
    if system == "linux":
        # Check for build-essential, cmake, etc.
        tools = ['gcc', 'g++', 'make', 'cmake']
        missing = []
        for tool in tools:
            try:
                subprocess.run([tool, '--version'], capture_output=True)
            except FileNotFoundError:
                missing.append(tool)
        
        if missing:
            log_warning(f"Missing build tools: {', '.join(missing)}")
            log_info("Install with: sudo apt install build-essential cmake")
        else:
            log_success("Linux build tools available")
            
    elif system == "windows":
        # Check for Visual Studio or Build Tools
        vs_paths = [
            r"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools",
            r"C:\Program Files\Microsoft Visual Studio\2022\Community",
            r"C:\Program Files\Microsoft Visual Studio\2022\Professional",
            r"C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
        ]
        
        vs_found = any(os.path.exists(path) for path in vs_paths)
        if vs_found:
            log_success("Visual Studio Build Tools found")
        else:
            log_warning("Visual Studio Build Tools not detected")
            
    elif system == "darwin":
        # Check for Xcode command line tools
        try:
            result = subprocess.run(['xcode-select', '--version'], capture_output=True)
            if result.returncode == 0:
                log_success("Xcode command line tools available")
            else:
                log_warning("Xcode command line tools not installed")
                log_info("Install with: xcode-select --install")
        except FileNotFoundError:
            log_warning("Xcode command line tools not found")

def check_disk_space():
    """Check available disk space"""
    try:
        import shutil
        total, used, free = shutil.disk_usage('.')
        free_gb = free // (1024**3)
        
        if free_gb < 20:
            log_error(f"Insufficient disk space: {free_gb}GB free, need at least 20GB")
            return False
        elif free_gb < 50:
            log_warning(f"Low disk space: {free_gb}GB free, recommend 50GB+")
        else:
            log_success(f"Disk space OK: {free_gb}GB available")
        return True
    except Exception as e:
        log_warning(f"Could not check disk space: {e}")
        return True

def check_memory():
    """Check available memory"""
    try:
        import psutil
        memory = psutil.virtual_memory()
        total_gb = memory.total // (1024**3)
        
        if total_gb < 8:
            log_warning(f"Low memory: {total_gb}GB, recommend 8GB+ for CEF builds")
        else:
            log_success(f"Memory OK: {total_gb}GB available")
        return True
    except ImportError:
        log_info("psutil not available - cannot check memory")
        return True

def validate_config():
    """Validate build configuration"""
    config_file = "build-config.json"
    if not os.path.exists(config_file):
        log_warning(f"Configuration file not found: {config_file}")
        return False
    
    try:
        with open(config_file) as f:
            config = json.load(f)
        
        required_keys = ['cef_version', 'target_platform', 'build_type']
        missing_keys = [key for key in required_keys if key not in config]
        
        if missing_keys:
            log_error(f"Missing configuration keys: {', '.join(missing_keys)}")
            return False
        
        log_success("Build configuration valid")
        return True
        
    except json.JSONDecodeError as e:
        log_error(f"Invalid JSON in {config_file}: {e}")
        return False

def check_submodules():
    """Check git submodules"""
    if not os.path.exists('.git'):
        log_warning("Not in a git repository")
        return False
    
    if not os.path.exists('cef-source'):
        log_error("CEF source submodule not found")
        log_info("Run: git submodule update --init --recursive")
        return False
    
    # Check if submodule is populated
    if not os.listdir('cef-source'):
        log_error("CEF source submodule is empty")
        log_info("Run: git submodule update --init --recursive")
        return False
    
    log_success("CEF source submodule OK")
    return True

def main():
    """Main environment check"""
    log_info("BuildingCEF Environment Setup and Validation")
    log_info(f"Platform: {platform.system()} {platform.release()}")
    log_info(f"Architecture: {platform.machine()}")
    
    checks = [
        ("Python Version", check_python_version),
        ("Git", check_git),
        ("Docker", check_docker),
        ("Build Tools", check_build_tools),
        ("Disk Space", check_disk_space),
        ("Memory", check_memory),
        ("Configuration", validate_config),
        ("Submodules", check_submodules)
    ]
    
    passed = 0
    failed = 0
    
    print("\n" + "="*50)
    print("ENVIRONMENT VALIDATION")
    print("="*50)
    
    for check_name, check_func in checks:
        print(f"\nChecking {check_name}...")
        try:
            if check_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            log_error(f"Check failed with exception: {e}")
            failed += 1
    
    print("\n" + "="*50)
    print("SUMMARY")
    print("="*50)
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    
    if failed == 0:
        log_success("Environment validation passed! Ready to build CEF.")
        return 0
    else:
        log_warning(f"Environment validation completed with {failed} issues.")
        log_info("Please address the issues above before building CEF.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
