#!/usr/bin/env python3
"""
test-setup.py - Quick setup validation script
"""

import os
import sys
import subprocess
import json

def test_config():
    """Test configuration file"""
    if not os.path.exists('build-config.json'):
        print("❌ build-config.json missing")
        return False
    
    try:
        with open('build-config.json') as f:
            config = json.load(f)
        print("✅ build-config.json valid")
        print(f"   CEF version: {config.get('cef_version', 'unknown')}")
        return True
    except:
        print("❌ build-config.json invalid")
        return False

def test_dockerfiles():
    """Test Dockerfiles exist"""
    dockerfiles = ['Dockerfile.linux', 'Dockerfile.windows', 'Dockerfile.macos']
    for dockerfile in dockerfiles:
        if os.path.exists(dockerfile):
            print(f"✅ {dockerfile} exists")
        else:
            print(f"❌ {dockerfile} missing")
            return False
    return True

def test_scripts():
    """Test scripts exist and are executable"""
    scripts = [
        'scripts/bootstrap/install-docker.sh',
        'scripts/bootstrap/install-docker.ps1', 
        'scripts/bootstrap/install-docker-macos.sh',
        'scripts/build-docker.sh',
        'scripts/build-venv.sh',
        'scripts/setup-environment.py',
        'scripts/update-cef.py'
    ]
    
    for script in scripts:
        if os.path.exists(script):
            if os.access(script, os.X_OK):
                print(f"✅ {script} exists and executable")
            else:
                print(f"⚠️  {script} exists but not executable")
        else:
            print(f"❌ {script} missing")
            return False
    return True

def test_build_drivers():
    """Test build drivers exist"""
    drivers = ['SConstruct', 'CMakeLists.txt', 'build.py']
    for driver in drivers:
        if os.path.exists(driver):
            print(f"✅ {driver} exists")
        else:
            print(f"❌ {driver} missing")
            return False
    return True

def test_submodule():
    """Test CEF submodule"""
    if not os.path.exists('cef-source'):
        print("❌ cef-source submodule missing")
        print("   Run: git submodule update --init --recursive")
        return False
    
    if not os.listdir('cef-source'):
        print("❌ cef-source submodule empty")
        print("   Run: git submodule update --init --recursive")
        return False
    
    print("✅ cef-source submodule OK")
    return True

def main():
    print("🔍 BuildingCEF Setup Validation")
    print("=" * 40)
    
    tests = [
        ("Configuration", test_config),
        ("Dockerfiles", test_dockerfiles),
        ("Scripts", test_scripts),
        ("Build Drivers", test_build_drivers),
        ("CEF Submodule", test_submodule)
    ]
    
    passed = 0
    total = len(tests)
    
    for name, test_func in tests:
        print(f"\n{name}:")
        if test_func():
            passed += 1
    
    print(f"\n{'=' * 40}")
    print(f"Tests passed: {passed}/{total}")
    
    if passed == total:
        print("✅ Setup validation passed! Ready to build CEF.")
        print("\nNext steps:")
        print("  scons                    # Build using SCons")
        print("  python build.py          # Build using Python")
        print("  python scripts/setup-environment.py  # Detailed environment check")
        return 0
    else:
        print("❌ Setup validation failed. Please fix the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
