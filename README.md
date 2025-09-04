# Zephyr Development Environment

A comprehensive Docker-based development environment for Zephyr RTOS with VS Code Dev Container support, optimized for ARM and ESP32 development.

## ✨ Key Improvements

### 🚀 **Optimized Zephyr Module Caching**
- Pre-cached Zephyr v4.1.0 in `/opt/zephyr-project/zephyr` 
- No need to re-download Zephyr core when running `west update`
- Only application-specific modules are updated
- Faster workspace initialization

### 🛠️ **VS Code Dev Container with Feature Architecture**
- Custom Zephyr development Feature in `.devcontainer/features/zephyr-dev/`
- Reusable across projects - just reference the Feature
- Comprehensive VS Code extensions for embedded development
- Pre-configured debugging with J-Link support

### 🔧 **Development Tools & Scripts**
- **Claude Code CLI** integrated with aliases (`cc`, `cchelp`)
- **Development aliases**: `zb` (build), `zbf` (flash), `wu` (update), etc.
- **Board shortcuts**: `zb_nrf52840dk`, `zb_nucleo`, `zb_esp32`, `zb_rpi_pico`
- **Code quality tools**: clang-format, cppcheck, pre-commit hooks
- **Helper functions**: `zephyr_init`, `zephyr_clean_build`, `zephyr_size`

### 🐛 **Hardware Debugging**
- J-Link debugger support with pre-configured launch configurations
- Multiple debug targets: ARM Cortex-M, Nordic nRF, STM32
- Port forwarding for debugging (2331, 19021)
- Serial monitor integration

## 🚀 Quick Start

### Option 1: VS Code Dev Container (Recommended)
1. Open in VS Code with Dev Containers extension
2. Command Palette → "Dev Containers: Reopen in Container"
3. Initialize workspace: `init-workspace.sh`
4. Build: `west build -b nrf52840dk_nrf52840 /opt/zephyr-project/zephyr/samples/hello_world`

### Option 2: Docker Compose
```bash
# Start development environment
docker-compose up -d zephyr-dev
docker exec -it zephyr-dev bash

# Initialize workspace and build
init-workspace.sh
west build -b nrf52840dk_nrf52840 /opt/zephyr-project/zephyr/samples/hello_world
```

### Option 3: Direct Docker
```bash
docker run -it --rm \
  -v $(pwd):/workdir \
  --privileged \
  --device /dev/bus/usb:/dev/bus/usb \
  -p 2331:2331 -p 19021:19021 \
  jaybuckeye06/zephyr-env:latest
```

## 📁 Project Structure

```
.
├── .devcontainer/
│   ├── devcontainer.json           # Dev container configuration
│   └── features/
│       └── zephyr-dev/             # Reusable Zephyr development feature
├── .vscode/
│   ├── launch.json                 # Debug configurations
│   └── settings.json               # VS Code settings
├── scripts/
│   ├── init-workspace.sh           # Workspace initialization
│   ├── dev-aliases.sh              # Development aliases
│   └── code-quality.sh             # Code formatting/linting
├── docker-compose.yml              # Development orchestration
├── Dockerfile                      # Multi-stage build
├── west.yml                        # Zephyr manifest
└── README.md                       # This file
```

## 🔨 Development Workflow

### Workspace Setup
```bash
# Initialize new project workspace
init-workspace.sh /path/to/your/project

# The script creates:
# - .west/config pointing to pre-cached Zephyr
# - west.yml with your project modules
# - Environment variables
```

### Building & Flashing
```bash
# Quick aliases available
zb                          # west build
zb_nrf52840dk              # west build -b nrf52840dk_nrf52840  
zbf                        # west build -t flash
zbm                        # west build -t menuconfig
wu                         # west update --exclude-west

# Traditional commands still work
west build -b esp32_devkitc_wroom
west flash
west debug
```

### Code Quality
```bash
# Format code
code-quality.sh format

# Check formatting
code-quality.sh check

# Setup pre-commit hooks
pre-commit install
```

### Debugging
1. Set breakpoints in VS Code
2. Press F5 or use "Run and Debug" panel
3. Choose target: ARM Cortex-M, Nordic nRF, or STM32
4. Hardware debugging via J-Link

## 🏗️ Architecture Features

### Multi-stage Docker Build
- **Base stage**: Ubuntu 22.04 with essential tools
- **SDK stage**: Zephyr SDK 0.17.0 + toolchains  
- **Source stage**: Pre-cached Zephyr project
- **Final stage**: Example application ready

### Dev Container Feature System
The `.devcontainer/features/zephyr-dev/` directory contains a reusable Feature that:
- Installs Zephyr-specific extensions automatically
- Configures file associations and IntelliSense
- Sets up debugging configurations
- Provides development tasks and shortcuts
- Can be used in any Zephyr project

### Optimized Module Management
- Zephyr core (800MB+) cached in Docker layer at `/opt/zephyr-project/zephyr`
- Workspace points to cached version via `.west/config`
- Only project-specific modules downloaded during `west update --exclude-west`
- Significantly faster than downloading full Zephyr each time

## 🔧 Supported Targets

### Hardware Platforms
- **Nordic**: nRF52840, nRF9160
- **NXP**: RT1061, RT1052  
- **STM32**: F429ZI, F746ZG
- **Espressif**: ESP32, ESP32-S2, ESP32-C3
- **Raspberry Pi**: Pico/RP2040

### Debugging Support
- **J-Link**: Hardware debugging for ARM Cortex-M
- **OpenOCD**: Alternative debugging backend
- **Serial Monitor**: UART communication
- **RTT**: Real-time transfer for Nordic devices

## 📦 Building Custom Images

```bash
# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 \
  -t your-repo/zephyr-env:latest .

# Push to registry  
docker push your-repo/zephyr-env:latest
```

## 🎯 Best Practices

1. **Use the Feature**: Reference `.devcontainer/features/zephyr-dev` in your projects
2. **Cache optimization**: Always use `west update --exclude-west` 
3. **Development flow**: Initialize → Build → Debug → Test
4. **Code quality**: Enable pre-commit hooks and formatting
5. **Hardware access**: Use `--privileged` flag for device programming

## 🔍 Troubleshooting

### Common Issues
- **Permission denied on USB devices**: Use `--privileged` or add `--device` flags
- **West update slow**: Use `wu` alias (excludes cached Zephyr core)  
- **IntelliSense not working**: Ensure C++ extension uses cmake-tools provider
- **Debug connection failed**: Check J-Link installation and device connection

### Environment Variables
```bash
ZEPHYR_BASE=/opt/zephyr-project/zephyr
ZEPHYR_PROJECT_ROOT=/opt/zephyr-project
ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details. 