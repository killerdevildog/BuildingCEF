# BuildingCEF 🏗️

<div align="center">

![CEF Logo](https://bitbucket.org/chromiumembedded/cef/raw/master/cef_logo_small.png)

**A modern, automated CEF (Chromium Embedded Framework) build environment**

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Supported-2496ED?logo=docker)](https://docker.com)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?logo=python)](https://python.org)

*Designed as a Git submodule for seamless integration into your projects*

</div>

## 📋 Overview

BuildingCEF is a specialized repository designed to be used as a **Git submodule** in your projects that require the Chromium Embedded Framework (CEF). It provides an automated, isolated build environment that simplifies the complex process of building CEF from source.

### 🎯 Key Features

- 🔄 **Automatic Updates**: Keep your CEF builds current with minimal effort
- 🐳 **Docker Support**: Isolated build environment using containerization
- 🐍 **Python Virtual Environment**: Alternative lightweight isolation using venv
- 📦 **Submodule Ready**: Designed specifically for Git submodule integration
- 🛠️ **Cross-Platform**: Support for Linux, Windows, and macOS builds
- ⚡ **Automated Scripts**: One-command build process
- 🔧 **Configurable**: Customize build parameters for your specific needs

## 🚀 Quick Start

### As a Git Submodule

Add BuildingCEF to your project as a submodule:

```bash
# Add as submodule
git submodule add https://github.com/killerdevildog/BuildingCEF.git third-party/BuildingCEF

# Initialize and update
git submodule update --init --recursive
```

### Using Docker (Recommended)

```bash
# Navigate to the submodule directory
cd third-party/BuildingCEF

# Build CEF using Docker
./build-docker.sh
```

### Using Python Virtual Environment

```bash
# Navigate to the submodule directory
cd third-party/BuildingCEF

# Create and activate virtual environment
python -m venv cef-build-env
source cef-build-env/bin/activate  # Linux/macOS
# or
cef-build-env\Scripts\activate     # Windows

# Install dependencies and build
pip install -r requirements.txt
./build-venv.sh
```

## 📁 Project Structure

```
BuildingCEF/
├── 📄 README.md                 # This file
├── 🐳 Dockerfile               # Docker build environment
├── 🐍 requirements.txt         # Python dependencies
├── ⚙️ build-config.json        # Build configuration
├── 🔧 scripts/
│   ├── build-docker.sh         # Docker build script
│   ├── build-venv.sh          # Virtual environment build script
│   ├── setup-environment.py   # Environment setup
│   └── update-cef.py          # CEF version updater
├── 📦 builds/                  # Output directory for builds
└── 🔄 cache/                   # Build cache directory
```

## ⚙️ Configuration

Edit `build-config.json` to customize your build:

```json
{
  "cef_version": "latest",
  "target_platform": "linux64",
  "build_type": "Release",
  "python_version": "3.8",
  "chromium_branch": "stable",
  "custom_flags": []
}
```

## 🔄 Integration Workflow

### In Your Main Project

1. **Add as submodule** (one-time setup):
   ```bash
   git submodule add https://github.com/killerdevildog/BuildingCEF.git third-party/BuildingCEF
   ```

2. **Update your .gitmodules** to track a specific branch:
   ```ini
   [submodule "third-party/BuildingCEF"]
       path = third-party/BuildingCEF
       url = https://github.com/killerdevildog/BuildingCEF.git
       branch = main
   ```

3. **Include in your build process**:
   ```bash
   # In your main project's build script
   git submodule update --remote --merge
   cd third-party/BuildingCEF
   ./build-docker.sh
   cp builds/* ../../lib/cef/
   ```

### Automatic Updates

Set up automated CEF updates in your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Update CEF
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM
  workflow_dispatch:

jobs:
  update-cef:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: Update CEF Build
        run: |
          cd third-party/BuildingCEF
          ./build-docker.sh
```

## 🐳 Docker Environment

The Docker environment provides:
- ✅ Consistent build environment across platforms
- ✅ All necessary dependencies pre-installed
- ✅ Isolated from host system
- ✅ Reproducible builds

### Requirements
- Docker Engine 20.10+
- 8GB+ available disk space
- 4GB+ RAM

## 🐍 Virtual Environment Setup

For lighter-weight builds without Docker:

### Requirements
- Python 3.8+
- Git
- CMake 3.19+
- Platform-specific build tools (GCC, Clang, or MSVC)

## 📋 Supported Platforms

| Platform | Docker | Venv | Status |
|----------|--------|------|--------|
| Linux x64 | ✅ | ✅ | Stable |
| Windows x64 | ✅ | ✅ | Stable |
| macOS x64 | ✅ | ✅ | Beta |
| macOS ARM64 | ✅ | ❌ | Planned |

## 🔧 Troubleshooting

### Common Issues

**Docker build fails with permission errors:**
```bash
sudo chmod +x scripts/*.sh
sudo chown -R $USER:$USER .
```

**Virtual environment Python version mismatch:**
```bash
python3.8 -m venv cef-build-env  # Use specific Python version
```

**Build cache issues:**
```bash
rm -rf cache/
./build-docker.sh --no-cache
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [CEF Official Repository](https://bitbucket.org/chromiumembedded/cef)
- [CEF Documentation](https://cef-builds.spotifycdn.com/docs.html)
- [Chromium Embedded Framework](https://cef-builds.spotifycdn.com/)

## 📞 Support

- 🐛 [Report Issues](https://github.com/killerdevildog/BuildingCEF/issues)
- 💬 [Discussions](https://github.com/killerdevildog/BuildingCEF/discussions)
- 📧 Contact: [your-email@example.com](mailto:your-email@example.com)

---

<div align="center">

**Made with ❤️ for the CEF community**

[![Stars](https://img.shields.io/github/stars/killerdevildog/BuildingCEF?style=social)](https://github.com/killerdevildog/BuildingCEF/stargazers)
[![Forks](https://img.shields.io/github/forks/killerdevildog/BuildingCEF?style=social)](https://github.com/killerdevildog/BuildingCEF/network/members)

</div> 
