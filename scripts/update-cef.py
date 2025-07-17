#!/usr/bin/env python3
"""
update-cef.py - CEF version updater script
"""

import os
import sys
import json
import requests
import subprocess
from pathlib import Path

def log_info(message):
    print(f"[INFO] {message}")

def log_success(message):
    print(f"[SUCCESS] {message}")

def log_warning(message):
    print(f"[WARNING] {message}")

def log_error(message):
    print(f"[ERROR] {message}")

def get_latest_cef_version():
    """Get the latest CEF version from the official builds API"""
    try:
        log_info("Fetching latest CEF version...")
        response = requests.get("https://cef-builds.spotifycdn.com/index.json", timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        # Get the latest stable version
        if "linux64" in data and "versions" in data["linux64"]:
            versions = data["linux64"]["versions"]
            if versions:
                latest = versions[0]  # First version is usually the latest
                version = latest.get("cef_version", "unknown")
                branch = latest.get("chromium_version", "unknown")
                log_success(f"Latest CEF version: {version} (Chromium: {branch})")
                return version, branch
        
        log_error("Could not parse CEF version data")
        return None, None
        
    except requests.RequestException as e:
        log_error(f"Failed to fetch CEF version: {e}")
        return None, None
    except json.JSONDecodeError as e:
        log_error(f"Failed to parse CEF version JSON: {e}")
        return None, None

def load_config():
    """Load build configuration"""
    config_file = "build-config.json"
    if not os.path.exists(config_file):
        log_error(f"Configuration file not found: {config_file}")
        return None
    
    try:
        with open(config_file) as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        log_error(f"Invalid JSON in {config_file}: {e}")
        return None

def save_config(config):
    """Save build configuration"""
    config_file = "build-config.json"
    try:
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        log_success(f"Configuration updated: {config_file}")
        return True
    except Exception as e:
        log_error(f"Failed to save configuration: {e}")
        return False

def update_submodule():
    """Update CEF source submodule"""
    log_info("Updating CEF source submodule...")
    
    try:
        # Update the submodule to latest
        result = subprocess.run([
            'git', 'submodule', 'update', '--remote', '--merge', 'cef-source'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            log_success("CEF submodule updated successfully")
            return True
        else:
            log_error(f"Failed to update submodule: {result.stderr}")
            return False
            
    except FileNotFoundError:
        log_error("Git not found")
        return False
    except Exception as e:
        log_error(f"Failed to update submodule: {e}")
        return False

def main():
    """Main update function"""
    log_info("CEF Version Updater")
    
    # Load current configuration
    config = load_config()
    if not config:
        return 1
    
    current_version = config.get('cef_version', 'unknown')
    log_info(f"Current CEF version: {current_version}")
    
    # Get latest version
    latest_version, latest_branch = get_latest_cef_version()
    if not latest_version:
        log_error("Could not determine latest CEF version")
        return 1
    
    # Check if update is needed
    if current_version == latest_version:
        log_info("CEF is already up to date")
        return 0
    
    # Ask for confirmation
    if len(sys.argv) < 2 or sys.argv[1] != '--auto':
        response = input(f"Update from {current_version} to {latest_version}? (y/N): ")
        if response.lower() not in ['y', 'yes']:
            log_info("Update cancelled")
            return 0
    
    # Update configuration
    config['cef_version'] = latest_version
    if latest_branch and latest_branch != 'unknown':
        config['chromium_branch'] = latest_branch
    
    if not save_config(config):
        return 1
    
    # Update submodule
    if not update_submodule():
        log_warning("Failed to update submodule, but configuration was updated")
        return 1
    
    log_success(f"CEF updated from {current_version} to {latest_version}")
    log_info("Run your build command to build the new version")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
